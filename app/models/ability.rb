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
		
		if current_user.admin? || current_user.superuser? || current_user.contributor?
			can [:create, :show, :add_user, :remove_user, :index, :edit, :update, :destroy], Collection
			can [:create, :show, :add_user, :remove_user, :index, :edit, :update, :destroy, :regenerate], GenericFile
			can [:create, :show, :add_user, :remove_user, :index, :edit, :update, :destroy], Institution
	#		cannot [:create, :show, :add_user, :remove_user, :index, :edit, :update, :destroy], GenericFile
	  else
	    cannot [:create, :show, :add_user, :remove_user, :index, :edit, :update, :destroy], Collection
			cannot [:create, :show, :add_user, :remove_user, :index, :edit, :update, :destroy, :regenerate], GenericFile
			cannot [:create, :show, :add_user, :remove_user, :index, :edit, :update, :destroy], Institution
		end
		
		#cannot :manage, ::Collection unless current_user.superuser?
  end
end
