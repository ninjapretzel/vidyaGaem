class Unit
	include Mongoid::Document
	include GameData
	
	field :name, type: String, default: "Unnamed"
	field :job, type: String, default: "NEET"
	field :team, type: String, default: "player"
	
	def team_sym; team.to_sym end
	
	field :equipment_slots, type: Array, default: []
	field :data, type: Hash, default: ->{ 
		h={
			level: 1,
			exp: 0.0,
			tnl: 1000.0,
			auto_attack_timer: 0.0,
			auto_attack_time: 3.0,
		}
		baseStats.each { |stat| h[stat] = 5 }
		h.default = 0
		h 
	}
	
	field :equip, type: Hash, default: ->{ h={}; h }
	
	#user this unit belongs to, if any
	belongs_to :user
	#Fight this unit is participating in, if any.
	belongs_to :combat
	
	
	accessors_through :data, vitals
	accessors_through :data, baseStatsCalc
	accessors_through :data, combatStats
	accessors_through :data, combatRatios
	accessors_through :data, intermediate
	accessors_through :data, [:victories, :losses]
	accessors_through :data, [:exp, :tnl]
	
	def auto_attack; Skill.find(data[:auto_attack]); end
	def auto_attack=(v) data[:auto_attack] = v._id; v.save; end
	
	def Unit.merc
		m = Unit.new
		m.name = japanese_name
		m.job = "Mercenary"
		m.equipment_slots = [ :head, :body, :hand, :legs, :feet, :hand_right, :hand_left]
		m.equip = { 
			head: { name: "Watermelon Hat", pdef:0.05, mhp:30 }, 
			body: { name: "Bloodstained Cotton Shirt", pdef:0.1, mhp:25 }, 
			hand: { name: "Sweaty Palm Gloves", pdef:0.05, mhp:10 }, 
			legs: { name: "Stained Trousers", pdef:0.1, mhp:15 }, 
			feet: { name: "Worn Out Walkers", pdef:0.05, mhp:15 },
			hand_right: { name: "Butter Knife", patk:5, aspd:2.5 },
			hand_left: { name: "Pan Lid", pdef:0.05, mhp:15 },
		}
		m.auto_attack = default_auto_attack
		m.recalc
		m.fullheal
		
		m
	end
	
	def Unit.monster(type, level, combo = 1) 
		mon = monsters(type)
		if mon.nil?; return nil; end
		scales = mon[:stats]
		
		elite_rank = 0
		
		m = Unit.new
		
		m.name = japanese_name + " the " + type.to_s.capitalize
		m.team = "monster"
		m.job = (elite_rank > 0) ? "Elite *" + elite_rank : "Mook"
		m.data[:level] = level
		
		level_scale = (level + 10.0) / 10.0
		base_stat = 2 * level_scale + 2 * elite_rank * level_scale
		baseStats.each { |stat| m.data[stat] = base_stat * scales.xt(stat, 1) }
		
		mul = combine[:mul]
		m.recalc

		m.data.combine!(scales, mul)
		m.auto_attack = default_auto_attack

		m.fullheal
		
		m.save
		m
	end
	
	
	def _id; id.to_s end
	
	def path; "/units/"+_id end
	
	def in_combat?; !combat.nil? end
	def dead?; data[:hp] <= 0 end
	
	def has_equipment() if equipment_slots; equipment_slots.length > 0 else; false end end
	def time; data[:auto_attack_time] end	
	def timer; data[:auto_attack_timer] end	
	def timer=(v); data[:auto_attack_timer]=v end	
	
	
	

	def fullheal
		self.hp = mhp
		self.mp = mmp
		self.sp = msp
	end

	def update(delta)
		if in_combat? && !dead?
			self.timer += delta * data[:aspd]
			if timer > time
				self.timer -= time
				target = target_one_enemy
				#puts name + " attacks " + target.name
				if data[:auto_attack].nil?; auto_attack = default_auto_attack end
				cast_skill(auto_attack)
			end
			
			
			
		end
	end
	
	def target_one_enemy; if in_combat?; combat.opposition[team_sym].choose else; nil end end
	def target_all_enemy; if in_combat?; combat.opposition[team_sym] else; nil end end
	def target_self; if in_combat?; self else; nil end end
	def target_one_ally; if in_combat?; combat.by_team[team_sym].choose else; nil end end
	def target_all_ally; if in_combat?; combat.by_team[team_sym] else; nil end end
	
	def cast_skill(skill)
		if mp < skill.mp_cost; return false end
		if sp < skill.sp_cost; return false end
		#if (!skill.ready) { return false; }
		
		self.mp -= skill.mp_cost
		self.sp -= skill.sp_cost
		#skill.use
		
		if (skill.aoe?)
			tgs = skill.supportive? ? target_all_ally : target_all_enemy
			tgs.each do |tg|
				target = Unit.find(tg)
				#target.apply_results(use_skill(skill))
			end
		else
			tg = skill.supportive? ? target_one_ally : target_one_enemy
			if skill.is_self?; target = self end
			if tg
				target = combat.units.where(_id: tg)
				puts self.inspect + "\n\n Attacking: " + target.inspect
				
				combat.log name + " uses " + skill.name + " on " + target.name
				target.apply_results(use_skill(skill))
			end
		end
		
	end

	def use_skill(skill)
		if skill
			results = {}
			crit_roll = Random.value
			results[:skill] = skill.name
			results[:source] = name
			results[:crit] = crit_roll < (crit + skill.crit_mod)
			
			if skill.damage; use_attack(skill, results) end
			return results
		else
			return nil
		end
		
	end

	def use_attack(skill, results)
		dmg = []
		model = skill.damage
		
		case model
			when Hash
				dmg.push single_hit(model, results)
			when Array
				model.each {|d| dmg.push single_hit(d, results)}
		end
		
		
		results[:damage] = dmg
	end

	def single_hit(info, results)
		crit = results[:crit]
		magical = info[:magical] ? true : false
		
		o = {}
		
		hit_roll = Random.value
		hit = hit_roll < (magical ? macc : pacc)
		if !hit
			o[:miss] = true
			return o
		end
		
		element = info[:element]
		if element == :inherited
			#TBD: Look up element from equipment...
			element = :crush
		end
		
		stat = info[:stat]
		base_amt = info.xt(:base_amt, 0)
		stat_dmg = data[stat]
		stat_mult = info.xt(:stat_mult, 1)
		
		dmg = base_amt + (stat_dmg * stat_mult)
		dmg *= crit ? 2.5 : 1
		
		roll = Random.range(0.9, 1.15)
		o[:dmg] = dmg * roll
		o[:magical] = magical
		o[:element] = element
		
		return o
	end

	def apply_results(results)
		if dead?; return false end
		if results.nil?; return false end
		
		if results[:damage]; apply_damage(results) end
		
	end



	def apply_damage(results)
		if hp <= 0; return false end
		damage = results[:damage]
		
		crit = results[:crit]
		anti_crit = crit ? (Random.value < resi) : false
		
		total_damage = 0
		evaded_any = false
		
		damage.each do |info|
			if info[:miss]; next end
			
			dmg = info[:dmg]
			element = info[:element]
			magical = info[:magical]
			
			evade_roll = Random.value
			evaded = evade_roll < (magical ? meva : peva);
			if evaded; evaded_any = true; next end
			
			resistance = data[element.prefix_with("res_")] || 0
			reduction = 1.0 - resistance.ratio(magical ? mdef : pdef)
			
			total_damage += dmg * reduction
		end
		
		if anti_crit
			crit = false
			total_damage *= 0.4
		end
		total_damage = total_damage.floor
		
		puts "\n\n\n" + name + ": HELP IM BEING ASSAULTED!!\n"
		puts combat.inspect
		
		if total_damage <= 0
			if evaded_any
				combat.log name + " dodged nimbly."
			else
				combat.log results[:source] + " missed horribly."
			end
		else
			combat.log name + " took " + total_damage.to_s + (crit ? " CRITICAL" : "")+ " damage."
			self.hp -= total_damage
			if hp <= 0
				die
				return true
			end
		end
		
		return false
	end

	def die
		combat.log name + " has been felled!"
	end

	def recalc
		
		groups = {}
		rules.each {|k, v| groups[k] = {} }
		groups[:baseStats] = data.mask(baseStatsCalc)
		groups[:combatStats] = baseCombatStats.mask(combatStats)
		groups[:combatRatios] = baseCombatStats.mask(combatRatios)
		
		if has_equipment
			equipment_slots.each do |slot|
				equip_piece = equip[slot]
				if equip_piece
					apply_statcalc(groups, equip_piece)
				end
			end
		end
		
		genstats = groups[:baseStats].matmul(combatStatCalc)
		apply_statcalc(groups, genstats)
		
		results = {}; results.default = 0
		group_combine.each { |s| results = results.add(groups[s]) }
		conversions.each { |conv| apply_conversion(results, conv) }
		floors.each { |s| if results.has_key? s; results[s] = results[s].floor end }
		
		self.data.set!(results)
	end

	def apply_conversion(results, rule)
		curve = curves[rule[:curve]]
		cmbrule = combine[rule[:combine]]
		stat = rule[:stat]
		source = rule[:source]
		
		sourceval = results.extract(source, 0)
		
		vals = rule.add({x: sourceval})
		
		eval = curve.call(vals)	
		
		statval = results[stat]
		results[stat] = cmbrule.call(eval, statval)
	end
	   
	def apply_statcalc(groups, thing)
		if thing
			rules.each do |key, rule|
				check_rule = $statcalc_data[key]
				case check_rule
					when Hash; mask = thing.get_matching_keys(check_rule)
					when Array; mask = check_rule
				end
				lhs = groups[key]
				rhs = thing.mask(mask)
				
				method = combine[rule]
				result = lhs.combine(rhs, method)
				
				groups[key] = result
			end
		end
	end
		
	
	def statsString
		s = name + " the " + job + " \n"
		s += _id + "\n"
		stats.each do |key, value|
			s += "#{key}: #{value}\n"
		end
		
		s
	end
	
end
