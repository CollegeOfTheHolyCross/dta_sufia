class InstitutionsController < ApplicationController
  include InstitutionsControllerBehavior
  before_action :verify_admin

  def create
    current_time = Time.now
    @collection[:date_created] =   [current_time.strftime("%Y-%m-%d")]
    super
  end

end