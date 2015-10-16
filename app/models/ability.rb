class Ability
  include Hydra::Ability
  include Sufia::Ability

  
  # Define any customized permissions here.
  def custom_permissions
    # Limits deleting objects to a the admin user
    #
    # if current_user.admin?
    #   can [:destroy], ActiveFedora::Base
    # end

    # Limits creating new objects to a specific group
    #
    # if user_groups.include? 'special_group'
    #   can [:create], ActiveFedora::Base
    # end
    
    
		if current_user.superuser?
			can [:create, :show, :add_user, :remove_user, :index, :edit, :update, :destroy], Role
		end
		
		if not user_groups.include? 'admin'
			cannot [:create, :show, :add_user, :remove_user, :index, :edit, :update, :destroy], Collection
			cannot [:create, :show, :add_user, :remove_user, :index, :edit, :update, :destroy], GenericFile
		end
		
		#cannot :manage, ::Collection unless current_user.superuser?
  end
end
