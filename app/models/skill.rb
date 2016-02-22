class Skill
	include Mongoid::Document
	include GameData
	
	field :data, type: Hash
		
	def _id; id.to_s end
	
	accessors_through :data, skillAccessors
	
	def	aoe?; type.contains?("area") end
	def supportive?; type.contains?("heal") || type.contains?("buff") end
	def is_self?; type.contains?("self") end
	
	def set_data(hash)
		self.data = hash.clone
		self.data.default = 0
		self.last_use = cooldown.seconds.ago
		save
	end
	
end