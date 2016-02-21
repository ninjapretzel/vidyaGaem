class UserController < EndUserBaseController
	before_action :set_unit, only: [:show_unit, ]
	
	def units
		@units = current_user.units
		
	end
	
	def new_unit
		@unit = Unit.merc
		
		
	end
	
	def show_unit
		
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
				
				format.html { redirect_to "/units/"+@unit._id, notice: 'Successfully hired merc.' }
			else
				format.html { render :new_unit }
				
			end
		end
		
		
	end
	
	
	private
		def set_unit
			@unit = Unit.find(params[:id])
		end
		def unit_params
			params.require(:unit).permit(:name, :job)
		end
	
	
end