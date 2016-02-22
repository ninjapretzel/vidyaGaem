class UserController < EndUserBaseController
	before_action :set_unit, only: [:show_unit, ]
	before_action :set_combat, only: [:show_combat, ]
	
	def units
		@units = current_user.units
		
	end
	
	def new_unit
		@unit = Unit.merc
		
		
	end
	
	def show_unit
		
	end
	
	def show_combat
		
	end
	
	def search_units
		name = params[:id]	
		@units = Unit.where(name: /#{name}/)
		puts "\n\n\nSearching for name " + name
		
		#render :units
		
	end
	
	def begin_combat
		@ps = params
		
		party = []
		
		@ps.each do |k, v|
			if k.to_s.prefix? "party"
				kk = k[5, 8]
				begin
					ind = Integer(kk)
					unit = current_user.units[ind]
					
					puts "Adding " + unit.name + " to party"
					if unit && !unit.in_combat?
						party.push unit
					end
					
				rescue => error
					
				end
			end
		end
			
		combat = nil
		if party.length > 0
			monsters = spawn_monsters_for party
			
			combat = Combat.new
			combat.set_units party + monsters
			combat.save
			puts "Combat successfully created with " + combat.units.length.to_s + " mofuggas"
		else 
			puts "party of size 0 too small to go adventuring. rip."
		end
		
		respond_to do |format|
			if combat
				combat.begin_fight
				puts "Combat successfully started with " + combat.units.length.to_s + " mofuggas"
				format.html { redirect_to combat.path, notice: "Combat became started" }
			else
				format.html { redirect_to units_path, notice: "Failed to start combat. Party needs at least one party member." }
			end
			
		end
		
	end
	
	def create_unit
		@unit = Unit.merc
		
		u = unit_params
		@unit.name = u[:name]
		@unit.job = u[:job]
		current_user.units << @unit
		
		respond_to do |format|
			if (@unit.save) 
				current_user.save
				
				format.html { redirect_to @unit.path, notice: 'Successfully hired merc.' }
			else
				format.html { render :new_unit }
				
			end
		end
		
		
	end
	
	
	private
		def spawn_monsters_for(party)
			monsters = []
			
			#Random.range(1, 4).times do
				monsters.push Unit.monster(:grizzly, 1)
			#end
			
			monsters
		end
			
		def set_unit; @unit = Unit.find(params[:id]) end
		def set_combat; @combat = Combat.find(params[:id]) end
		def unit_params
			params.require(:unit).permit(:name, :job)
		end
	
	
end