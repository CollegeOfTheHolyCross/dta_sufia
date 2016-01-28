class MyController < ApplicationController
  include Sufia::MyControllerBehavior
  include DtaStaticBuilder

  before_action :get_latest_content
  before_action :my_files_sort_fields

  self.search_params_logic -= [:add_access_controls_to_solr_params]

  def my_files_sort_fields
    uploaded_field = ActiveFedora::SolrQueryBuilder.solr_name('date_uploaded', :stored_sortable, type: :date)
    modified_field =  ActiveFedora::SolrQueryBuilder.solr_name('date_modified', :stored_sortable, type: :date)
    blacklight_config.sort_fields = {}
    blacklight_config.add_sort_field "score desc, #{uploaded_field} desc", label: "relevance"
    blacklight_config.add_sort_field "#{uploaded_field} desc", label: "date uploaded \u25BC"
    blacklight_config.add_sort_field "#{uploaded_field} asc", label: "date uploaded \u25B2"
    blacklight_config.add_sort_field "#{modified_field} desc", label: "date modified \u25BC"
    blacklight_config.add_sort_field "#{modified_field} asc", label: "date modified \u25B2"

    blacklight_config.add_sort_field 'title_primary_ssort asc, dta_sortable_date_dtsi asc', :label => "title \u25B2"
    blacklight_config.add_sort_field 'title_primary_ssort desc, dta_sortable_date_dtsi asc', :label => "title \u25BC"
    blacklight_config.add_sort_field 'dta_sortable_date_dtsi asc, title_primary_ssort asc', :label => "date \u25B2"
    blacklight_config.add_sort_field 'dta_sortable_date_dtsi desc, title_primary_ssort asc', :label => "date \u25BC"

    #blacklight_config.default_sort_field = blacklight_config.sort_fields["#{uploaded_field} desc"]
  end



end