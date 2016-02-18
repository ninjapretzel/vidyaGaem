class Unit
    include Mongoid::Document
    field :name, type: String
    
    field :job, type: String
    
    
    embeds_one :stat, as: :statistic
    
    belongs_to :user
    
    

end
