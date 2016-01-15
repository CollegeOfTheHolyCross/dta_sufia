class HomepageController < ApplicationController
  include Sufia::HomepageController
  include DtaStaticBuilder

  before_action :get_latest_content


  layout 'home'

  def index

  end
end
