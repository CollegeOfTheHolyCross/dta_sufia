class DashboardController < ApplicationController
  include Sufia::DashboardControllerBehavior
  include DtaStaticBuilder

  before_action :get_latest_content
end