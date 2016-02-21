class Combat
	attr_accessor :combatants, :by_team, :opposition, :clog
	
	def log(s)
		str = @time.to_s + ": " + s
		self.clog.push str
		puts str
	end
	
	def time; @time end
	
	def initialize(units)
		
		self.clog = []
		self.combatants = units.clone
		self.by_team = {}
		self.opposition = {}
		combatants.each { |c| 
			c.combat = self 
			team = by_team[c.team_sym] || []
			team.push c
			
			self.by_team[c.team_sym] = team
			
		}
		by_team.each {|team, dudes| opposition[team] = combatants - dudes }
		
		
	end
	
	def winning_team
		teams = []
		combatants.each do |c|
			if c.dead?; next end
			if !teams.include? c.team_sym; teams.push c.team_sym end
		end
		
		if teams.length == 1; teams[0] else; nil end
	end
	
	def begin_fight
		puts "Combat starting!!!"
		
		fight = Thread.new {
			start = Time.now
			last = start
			while true do
				now = Time.now
				delta = now-last
				@time = now-start
				#puts "Round GO! " + delta.to_s
				combatants.each do |c|
					c.update(delta)
				end
				
				winner = winning_team
				if winner
					break
				else
					last = now; sleep 0.1
				end
				
			end
			
			#remove fags from combat
			combatants.each { |c| 
				c.combat = nil; 
				if c.team_sym == winner
					c.victories += 1
				else
					c.losses += 1
				end
			}
			
			log "Team " + winner.to_s + " won"
			log "Combat finished after " + (now-start).to_s + " seconds"
			#puts by_team[winner].inspect
			
			
			
			
			
		}
		
	end
	
	
end