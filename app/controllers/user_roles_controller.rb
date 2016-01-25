class UserRolesController < ApplicationController
  include Hydra::RoleManagement::UserRolesBehavior

  def destroy
    authorize! :remove_user, @role
    @role.users.delete(::User.find(params[:id].gsub('-dot-', '.')))
    redirect_to role_management.role_path(@role)
  end
end