class MyController < ApplicationController
  include Sufia::MyControllerBehavior
  include DtaStaticBuilder

  before_action :get_latest_content

  self.search_params_logic -= [:add_access_controls_to_solr_params]
end