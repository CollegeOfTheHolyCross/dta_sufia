class MyController < ApplicationController
  include Sufia::MyControllerBehavior

  self.search_params_logic -= [:add_access_controls_to_solr_params]
end