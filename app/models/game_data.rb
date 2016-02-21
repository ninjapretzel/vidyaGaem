module GameData
	#empty module to force this file to be reloaded by like everything
	#because FUCK THE POLICE
	
end

class Class
	def accessors_through(hash, things)
		things.each do |thing|
			define_method thing.to_s do
				#puts "accessing " + thing.to_s
				got = self.send(hash)
				#puts got
				got[thing]
			end
			define_method (thing.to_s+"=") do |v| 
				self.send(hash)[thing] = v 
			end
		end
	end
	
end

class Random
	def self.value; rand(1.0) end
	def self.range(a,b) a+rand(b-a) end
end

class Numeric
	def clamp(min, max) if self<=min;min elsif self>=max;max else self end end
	def clamp01() if self<=0;0 elsif self>=1;1 else self end end
	def ratio(r) (1.0 - (1.0 - self.clamp01) * (1.0 - r.clamp01)) end
end

class String
	def prefix?(v) start_with?(v) end
	def suffix?(v) end_with?(v) end
	def contains?(v) include?(v) end
	
	def prefix_with(v) (v+self) end
	def suffix_with(v) (self+v) end
end

class Symbol
	def prefix?(v) to_s.prefix?(v) end
	def suffix?(v) to_s.suffix?(v) end
	def contains?(v) to_s.contains?(v) end
	
	def prefix_with(v) to_s.prefix_with(v).to_sym end
	def suffix_with(v) to_s.suffix_with(v).to_sym end
end

class Array
	def choose; self[Random.new.rand(length)] end
	
end


class Hash
	
	#Mask this hash with an array of symbols, or another hash
	#Returns a hash with self.keys intersect m, and their values
	def mask(m)
		c = {}
		
		case m
			when Hash; self.each { |k, v| if m.has_key? k; c[k] = v end }
			when Array; self.each { |k, v| if m.include? k; c[k] = v end }
			else;
		end
		
		
		c
	end

	def extract(key, default) if has_key? key; self[key] else; default end end
	def xt(key, default) if has_key? key; self[key] else; default end end

	def get_matching_keys(rule)
		if rule.nil?; rule = {} end
		result = []
		pf = rule.extract :prefix, ""
		sf = rule.extract :suffix, ""
		cn = rule.extract :contains, ""
		
		self.each {|k, v| 
			if k.prefix?(pf) && k.suffix?(sf) && k.contains?(cn)
				result.push k
			end
		}
		result
	end
	
	def neg; c = {}; c.default = 0; self.each {|k, v| c[k] = -v}; c end
	def sum; s = 0; self.each {|k,v| s += v}; s; end
	
	def set!(b) b.each { |k,v| self[k] = v }end
	
	def add(b)
		c = {};	c.default = 0
		case b
			when Hash; self.each { |k, v| c[k] = v }; b.each {|k, v| c[k] += v }
			when Numeric; self.each { |k, v| c[k] = v + b }
		end
		c
	end
	
	def mul(b)
		c = {};	c.default = 0
		case b
			when Hash; self.each { |k, v| if b.has_key? k; c[k] = v * b[k] end }
			when Numeric; self.each { |k, v| c[k] = v * b }
		end
		c
	end

	def rat(b)
		c = {}; c.default = 0
		self.each { |k,v| c[k] = c[k].ratio(v) }
		b.each { |k,v| c[k] = c[k].ratio(v) }
		c
	end

	def matmul(b)
		c = {};	c.default = 0
		b.each do |k, v|
			r = 0;
			case v
				when Hash; v.each { |kk, vv| r += self[kk] * vv }
				when Numeric; r = self[k] * v;
			end
			c[k] = r
		end
		c
	end
	
	def combine(b, method)
		c = {}; c.default = 0
		self.each { |k, v| c[k] = v }
		b.each { |k, v| c[k] = method.call(c[k], v) }
		c
	end
	
	def combine!(b, method)
		b.each { |k, v| if has_key? k; self[k] = method.call(self[k], v) end }
	end

end

$statcalc_data = {
	baseStatsCalc: [:level, :str, :dex, :int, :vit, :agi, :wis],
	baseStats: [:str, :dex, :int, :vit, :agi, :wis],
	vitals: [:hp, :mp, :sp],
	combatStats: [ 
		:mhp, :mmp, :msp, 
		:rhp, :rmp, :rsp, 
		:patk, :pacc, 
		:matk, :macc, 
		:aspd, :cspd, 
	],
	combatRatios: [ 
		:pdef, :peva, 
		:mdef, :meva, 
		:crit, :resi 
	],
	intermediate: [
		:armor, :shell,
		:rflex, :intut,
		:sight, :tough,
	],
	resistances: { prefix: "res_" }, 
	affinities: { prefix: "aff_" },
	floors: [
		:patk, :matk,
		:str, :dex, :vit, :agi, :int, :wis,
		:armor, :shell, :rflex,
		:intut, :sight, :tough,
		:mhp, :mmp, :msp,
	],
	group_combine:[
		:combatStats,
		:combatRatios,
		:intermediate,
		:resistances,
		:affinities,
	],
	rules: {
		baseStats: :add,
		combatStats: :add,
		intermediate: :add,
		affinities: :add,
		combatRatios: :ratio,
		resistances: :ratio,
	},
	conversions: [
		{
			curve: :asymp,
			source: :armor,
			r: 1600,
			cap: 0.95,
			stat: :pdef,
			combine: :ratio, 
		},
		{
			curve: :asymp,
			source: :shell,
			r: 1600,
			cap: 0.95,
			stat: :mdef,
			combine: :ratio, 
		},
		{
			curve: :log,
			source: :rflex,
			r: 0.01,
			cap: 0.95,
			base: 2.0,
			stat: :peva,
			combine: :ratio,	 
		},
		{
			curve: :log,
			source: :intut,
			r: 0.01,
			cap: 0.95,
			base: 2.0,
			stat: :meva,
			combine: :ratio,	 
		},
		{
			curve: :asymp,
			source: :sight,
			r: 3600,
			cap: 0.50,
			stat: :crit,
			combine: :ratio,	 
		},
		{
			curve: :asymp,
			source: :tough,
			r: 3600,
			cap: 0.95,
			base: 2.0,
			stat: :resi,
			combine: :ratio,	 
		}
	],
	combine: {
		add: -> (a,b) { a + b },
		mul: -> (a,b) { a * b },
		ratio: -> (a,b) { a.ratio(b) },
		set: -> (a,b) { b }
	},
	curves: {
		#y = ax + b
		linear: ->(d) {x=d[:x]||0;a=d[:a]||0;b=d[:b]||0; a*x+b },
		#y = ax^2 + bx + c
		square: ->(d) {x=d[:x]||0;a=d[:a]||0;b=d[:b]||0;c=d[:c]||0; a*x*x+b*x+c },
		#y = ax^3 + bx^2 + cx + d
		cube: ->(d) {x=d[:x]||0;a=d[:a]||0;b=d[:b]||0;c=d[:c]||0;e=d[:d]; a*x*x*x+b*x*x+c*x+d },
		#y = 1-r/(x+r) [0...cap]
		asymp: ->(d) {x=d.xt(:x,0);r=d.xt(:r,800);cap=d.xt(:cap,1); (1.0-(r / (x + r))).clamp(0, cap) },
		#y = r*log(x+base, base) [0...cap]
		log: ->(d) {x=d[:x]||0;r=d[:r]||1;cap=d[:cap]||0;base=d[:base]||0; (r * Math.log(x + base, base)).clamp(0, cap)},
	},
	curvesOLD: {
		linear: ->(x, m, b=0) { m * x + b },
		square: ->(x, a, b=0, c=0) { a * x*x + b * x + c },
		cube: ->(x, a, b=0, c=0, d=0) { a * x*x*x + b * x*x + c * x + d },
		asymp: ->(x, r, cap=1) { clamp((1.0-(r / (x + r))), 0, cap) },
		log: ->(x, r, cap=1, base=1.5, w=0) { clamp(Math.log(x + base, base), 0, cap) },
	},
	baseCombatStats: {
		mhp: 100.000, mmp:  10.000, msp:   5.000,
		rhp:   0.200, rmp:   0.100, rsp:   0.015,

		patk: 10.000, pacc:  0.500, pdef:  0.000, peva:  0.000,
		matk: 10.000, macc:  0.500, mdef:  0.000, meva:  0.000,

		crit:  0.000, resi:  0.000,
		aspd:  1.000, cspd:  1.000,
		armor: 0.000, rflex: 1.000,
		shell: 0.000, intut: 1.000,
		signt: 0.000, tough: 0.000,
	},
	expStatRates: {
		mhp:   0.100, mmp:   0.300, msp:   0.500,
		rhp:   0.300, rmp:   0.100, rsp:   0.100,

		patk:  0.200, pacc:  0.100, pdef:  1.000, peva:  2.000,
		matk:  1.000, macc:  0.100, mdef:  1.000, meva:  2.000,

		armor: 1.000, shell: 1.000, crit: 1.000, resi: 1.000,
		aspd:  3.000, cspd: 3.000,
	},
	combatStatCalc: {
		mhp:  { level: 30.000, vit:  5.400, str:  1.100, },
		mmp:  { level:  5.000, wis:  0.800, int:  0.125, }, 
		msp:  { level:  1.000, str:  0.125, dex:  0.125, agi:  0.125, vit:  0.125, int:  0.125, wis:  0.125, },

		rhp:  { level:  0.050, vit:  0.007, str:  0.003, },
		rmp:  { level:  0.020, wis:  0.002, int:  0.001, },
		rsp:  { level:  0.010, str:  0.001, dex:  0.001, agi:  0.001, vit:  0.001, int:  0.001, wis:  0.001, },

		patk:  { level:  4.000, str:  2.000, dex:  1.000, },
		pdef:  { level:  0.000, vit:  0.000, agi:  0.000, },
		pacc:  { level:  0.002, dex:  0.002, agi:  0.001, },
		peva:  { level:  0.000, agi:  0.000, dex:  0.000, },

		matk:  { level:  4.500, int:  2.150, wis:  1.020, },
		mdef:  { level:  0.000, vit:  0.000, wis:  0.000, },
		macc:  { level:  0.002, int:  0.001, wis:  0.002, },
		meva:  { level:  0.000, wis:  0.000, agi:  0.000, },

		aspd:  { level:  0.010, agi:  0.007, dex:  0.004, },
		cspd:  { level:  0.010, dex:  0.007, wis:  0.004, },

		crit:  { level:  0.000, agi:  0.001, dex:  0.001, int:  0.001, },
		resi:  { level:  0.000, str:  0.001, vit:  0.001, wis:  0.001, },

		armor:  { level:  0.000, vit:  4.000, agi:  2.000, },
		shell:  { level:  0.000, vit:  4.000, wis:  2.000, },

		rflex:  { level:  0.000, agi:  4.000, dex:  2.000, },
		intut:  { level:  0.000, wis:  4.000, agi:  2.000, },

		sight:  { level:  0.000, dex:  4.000, agi:  2.000, int:  2.000, },
		tough:  { level:  0.000, vit:  4.000, str:  2.000, wis:  2.000, },
	},
}

def vitals() $statcalc_data[:vitals] end
def baseStats() $statcalc_data[:baseStats] end
def baseStatsCalc() $statcalc_data[:baseStatsCalc] end
def combatStats() $statcalc_data[:combatStats] end
def combatRatios() $statcalc_data[:combatRatios] end
def intermediate() $statcalc_data[:intermediate] end
def resistances() $statcalc_data[:resistances] end
def affinities() $statcalc_data[:affinities] end
def floors() $statcalc_data[:floors] end
def conversions() $statcalc_data[:conversions] end
def rules() $statcalc_data[:rules] end
def group_combine() $statcalc_data[:group_combine] end
def combine() $statcalc_data[:combine] end
def curves() $statcalc_data[:curves] end
def baseCombatStats() $statcalc_data[:baseCombatStats] end
def expStatRates() $statcalc_data[:expStatRates] end
def combatStatCalc() $statcalc_data[:combatStatCalc] end

$drop_data = {
	standard: { type: :all, drops: [:equipment, :rare_gems] },
	rare_gems: { type: :all, drops: [ 
		{item: :mat_ruby, chance:0.01, rolls: 1},
		{item: :mat_sapphire, chance:0.01, rolls: 1},
		{item: :mat_emerald, chance:0.01, rolls: 1},
		{item: :mat_diamond, chance:0.01, rolls: 1},
	]},
	equipment: { type: :one, drops: [
		{item: :melee_weapon, chance:0.10, rolls: 1},
		{item: :heavy_armor, chance:0.10, rolls: 1},
		{item: :light_armor, chance:0.10, rolls: 1},
	]},
}

$itemgen_data = {
	#TBD
}

$monster_data = {
	grizzly: {
		stats: { str: 3, agi: 1, patk:0.5, pdef:0.2, mhp:1.1 },
		drops: [ :standard ],
	}
}

def monsters(type) $monster_data[type] end

$skill_setup = {
	accessors: [ 
		:name, :type, :desc, :icon, 
		:mp_cost, :sp_cost, 
		:cooldown, :last_use,
		:crit_mod,
		:damage,
	]
}
def skillAccessors() $skill_setup[:accessors] end

$skill_data = {
	auto_attack: {
		name: "Attack",
		type: :attack,
		desc: "Attack using equipped weapon.",
		icon: "Sword1",
		mp_cost: 0,
		sp_cost: 0,
		cooldown: 0,
		damage: {
			element: :inherited,
			stat: :patk,
			stat_mult: 1,
		},

	},

}

def default_auto_attack() Skill.new($skill_data[:auto_attack]) end


$namegen_data = {
	japanese: [
		"a", "i", "u", "e", "o",
		"ka", "ki", "ku", "ke", "ko",
		"ga", "gi", "gu", "ge", "go",
		"sa", "shi", "su", "se", "so",
		"za", "ji", "zu", "ze", "zo",
		"ta", "chi", "tsu", "te", "to",
		"da", "ji", "zu", "de", "do",
		"na", "ni", "nu", "ne", "no",
		"ha", "hi", "fu", "he", "ho",
		"ba", "bi", "bu", "be", "bo",
		"pa", "pi", "pu", "pe", "po",
		"ma", "mi", "mu", "me", "mo",
		"ya",       "yu",       "yo",
		"kya",      "kyu",      "kyo",
		"sha",      "shu",      "sho",
		"cha",      "chu",      "cho",
		"nya",      "nyu",      "nyo",
		"hya",      "hyu",      "hyo",
		"mya",      "myu",      "myo",
		"rya",      "ryu",      "ryo",
		"gya",      "gyu",      "gyo",
		"ja",       "ju",       "jo",
		"bya",      "byu",      "byo",
		"pya",      "pyu",      "pyo",
		"ra", "ri", "ru", "re", "ro",
		"wa", "wi",       "we", "wo",
	]

}

def japanese_name() 
	cnt = Random.range(1, 7).floor
	s = ""
	cnt.times do
		s += $namegen_data[:japanese].choose
	end

	s.capitalize
end
