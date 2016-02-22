class Combat
	include Mongoid::Document
	include GameData
	
	field :data, type: Hash
	
	has_many :units
	
	accessors_through :data, [:clog, :running, :final_winner, :combatant_names, :combatant_ids]
	accessors_through :data, [:by_team, :opposition]
	
	
	
	def _id; self.id.to_s end
	def path; "/combat/"+_id end
	
	def log(s)
		str = @time.to_s + ": " + s
		l = clog
		l.push str
		self.clog = l
		puts str
		save
	end
	
	def time; @time end
	
	def set_units(combatants)
		self.data = {}
		
		self.clog = []
		self.by_team = {}
		self.opposition = {}
		self.combatant_ids = []
		self.combatant_names = []
		self.final_winner = nil
		self.running = nil
		
		puts "Adding " + combatants.length.to_s + " Combatants " 
		combatants.each do |c|
			puts "adding " + c.name + " to combat" 
			units << c
			#c.combat.log "Uppermost jej"
			team = by_team[c.team_sym] || []
			team.push c._id
			self.by_team[c.team_sym] = team
			
			cids = combatant_ids
			cids.push c._id
			self.combatant_ids = cids
			
			cnames = combatant_names
			cnames.push(c.team + ":" + c.name)
			self.combatant_names = cnames
			
			c.save
		end
		
		by_team.each {|team, team_ids| opposition[team] = combatant_ids - team_ids }
		
		#puts "\n\nSet Up Combat:"
		#puts self.inspect
		
		self.save
	end
	
	def winning_team
		teams = []
		units.each do |c|
			if c.dead?; next end
			if !teams.include? c.team_sym; teams.push c.team_sym end
		end
		
		if teams.length == 1; teams[0] else; nil end
	end
	
	def begin_fight
		puts "Combat starting!!!"
		puts units.inspect
		self.running = true
		save
		
		fight = Thread.new {
			begin
				
				start = Time.now
				last = start
				
				while true do
					puts units.length.to_s + "MOFUGGAS"
					puts "\n\n\n\n"
					puts units.inspect
					
					now = Time.now
					delta = now-last
					@time = now-start
					#puts "Round GO! " + delta.to_s
					#log "YER A FUCKING FAGET"
					
					units.each do |c|
						#c.combat.log "Tippity Top Lel"
						c.update(delta)
						c.save

					end

					save
					
					winner = winning_team
					if winner
						break
					else
						last = now; sleep 0.1
					end

				end

				units.each { |c| 
					if c.team_sym == winner
						c.victories += 1
					else
						c.losses += 1
					end
					c.save
				}
				#remove fags from combat
				log "Combat finished after " + (now-start).to_s + " seconds"
				units.clear

				self.final_winner = winner.to_s
				self.running = false
				log "Team " + winner.to_s + " won"
				#puts by_team[winner].inspect

				save
			rescue => error
				puts error.inspect
				puts error.message
				puts error.backtrace.join("\n")
				save
			end
		}
		
		
		
			
		
	end
	
	
end