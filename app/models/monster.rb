class Monster
    include Mongoid::Document
    field :name, type: String
    
    
    embeds_one :stat, as: :statistic
    
    belongs_to :user
    
    validates_uniqueness_of :name
    
end
