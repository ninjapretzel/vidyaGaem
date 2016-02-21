class Skill
	attr_accessor :data
	
	accessors_through :data, skillAccessors
	
	def	aoe?; type.contains?("area") end
	def supportive?; type.contains?("heal") || type.contains?("buff") end
	def is_self?; type.contains?("self") end
	
	def initialize(hash)
		self.data = hash.clone
		self.data.default = 0
		self.last_use = cooldown.seconds.ago
	end
	
end