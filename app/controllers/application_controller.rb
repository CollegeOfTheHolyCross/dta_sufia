class ApplicationController < ActionController::Base
  helper Openseadragon::OpenseadragonHelper
  # Adds a few additional behaviors into the application controller 
  include Blacklight::Controller  
# Adds Sufia behaviors into the application controller (ApplicationController) 
  include Sufia::Controller

  include Hydra::Controller::ControllerBehavior
  layout 'sufia-one-column'

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def verify_superuser
    if !current_user.present? && !current_user.superuser?
      redirect_to root_path
    end
  end

  def verify_admin
    if !current_user.present? && !current_user.admin? && !current_user.superuser?
      redirect_to root_path
    end
  end

  def verify_contributor
    if !current_user.present? && !current_user.admin? && !current_user.superuser? && !current_user.contributor?
      redirect_to root_path
    end
  end

  def verify_homosaurus
    if !current_user.present? && !current_user.admin? && !current_user.superuser? && !current_user.homosaurus?
      redirect_to root_path
    end
  end
end
