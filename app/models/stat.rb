class Stat
    include Mongoid::Document
    
    embedded_in :statistic, polymorphic: true
    
    
    
    field :base_strength, type: Float
    field :base_dexterity, type: Float
    field :base_inteligence, type: Float
    
    field :base_vitality, type: Float
    field :base_agility, type: Float
    field :base_wisdom, type: Float
    
    
    
    
    
    
end
