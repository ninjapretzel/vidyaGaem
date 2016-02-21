class Item
	include Mongoid::Document
	belongs_to :user
	
end
