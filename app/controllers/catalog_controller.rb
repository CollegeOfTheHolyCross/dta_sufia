# -*- coding: utf-8 -*-
# -*- encoding : utf-8 -*-
#require 'blacklight/catalog'
require 'blacklight_advanced_search'

# bl_advanced_search 1.2.4 is doing unitialized constant on these because we're calling ParseBasicQ directly
require 'parslet'
require 'parsing_nesting/tree'

class CatalogController < ApplicationController
  include Hydra::Catalog
  include Hydra::Controller::ControllerBehavior
  include Sufia::Catalog
  include DtaSearchBuilder
  include DtaStaticBuilder

  before_action :get_latest_content

  # These before_filters apply the hydra access controls
  before_filter :enforce_show_permissions, only: :show
  # This applies appropriate access controls to all solr queries
  CatalogController.search_params_logic += [:add_access_controls_to_solr_params, :add_advanced_parse_q_to_solr, :exclude_unwanted_models]

  skip_before_filter :default_html_head

  def self.uploaded_field
    solr_name('date_uploaded', :stored_sortable, type: :date)
  end

  def self.modified_field
    solr_name('date_modified', :stored_sortable, type: :date)
  end

  configure_blacklight do |config|

    # collection name field
    config.collection_field = 'collection_name_ssim'
    # institution name field
    config.institution_field = 'institution_name_ssim'
    # solr field for flagged/inappropriate content
    config.flagged_field = 'flagged_ssi'

    config.view.gallery.default = true
    config.view.gallery.partials = [:index_header, :index]
          config.view.masonry.partials = [:index]
          config.view.slideshow.partials = [:index]

          config.show.tile_source_field = :content_metadata_image_iiif_info_ssm
          config.show.partials.insert(1, :openseadragon)

    # Show gallery view
    config.view.gallery.partials = [:index_header, :index]
    config.view.slideshow.partials = [:index]


    # blacklight-maps stuff
  config.view.maps.geojson_field = 'subject_geojson_facet_ssim'
  config.view.maps.coordinates_field = 'subject_coordinates_geospatial'
  config.view.maps.placename_field = 'subject_geographic_ssim'
  config.view.maps.maxzoom = 13
  config.view.maps.show_initial_zoom = 9
  config.view.maps.facet_mode = 'geojson'

    #set default per-page
    config.default_per_page = 20

    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = {
      qt: "search",
      rows: 20
    }

    # Specify which field to use in the tag cloud on the homepage.
    # To disable the tag cloud, comment out this line.
    config.tag_cloud_field_name = Solrizer.solr_name("tag", :facetable)

    # solr field configuration for document/show views
    config.index.title_field = solr_name("title", :stored_searchable)
    config.index.display_type_field = solr_name("has_model", :symbol)
    config.index.thumbnail_method = :sufia_thumbnail_tag

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    config.add_facet_field solr_name("creator", :facetable), label: "Creator", limit: 6, collapse:false
    config.add_facet_field 'dta_all_subject_ssim', :label => 'Topic', :limit => 6, :sort => 'count', :collapse => false
    config.add_facet_field 'dta_other_subject_ssim', :label => 'Subject', :limit => 6, :sort => 'count', :collapse => false
    config.add_facet_field 'dta_dates_ssim', :label => 'Date', :range => true, :collapse => false
    config.add_facet_field 'genre_ssim', :label => 'Genre', :limit => 6, :sort => 'count', :collapse => true
    config.add_facet_field 'subject_geographic_ssim', :label => 'Location', :limit => 6, :sort => 'count', :collapse => true
    config.add_facet_field 'collection_name_ssim', :label => 'Collection', :limit => 8, :sort => 'count', :collapse => true
    config.add_facet_field 'institution_name_ssim', :label => 'Institution', :limit => 8, :sort => 'count', :collapse => true
    config.add_facet_field 'subject_geojson_facet_ssim', :limit => -2, :label => 'Coordinates', :show => false

    # https://bibwild.wordpress.com/2011/06/13/customing-blacklight-a-limit-checkbox/
=begin
    config.add_facet_field 'a_query_field', partial: 'custom_format_facet', query: {
        :a_to_n => { label: 'A-N', fq: 'genre_ssim:[A* TO Z*]' },
        :m_to_z => { label: 'M-Z', fq: '-genre_ssim:"Finding Aids"' }
    }
=end
    config.add_facet_field 'dtalimits', label: "Limit", :show => false, query: {
        :ex_fa => { label: 'Exclude Finding Aids', fq: '-genre_ssim:"Finding Aids"' }
    }

    #config.add_facet_field solr_name("genre", :facetable), label: "Genre", limit: 6, :collapse => true
    #config.add_facet_field solr_name("resource_type", :facetable), label: "Resource Type", limit: 5



    #config.add_facet_field solr_name("tag", :facetable), label: "Keyword", limit: 5
    #config.add_facet_field solr_name("subject", :facetable), label: "Subject", limit: 5





    #config.add_facet_field solr_name("language", :facetable), label: "Language", limit: 5
    #config.add_facet_field solr_name("based_near", :facetable), label: "Location", limit: 5
    #config.add_facet_field solr_name("publisher", :facetable), label: "Publisher", limit: 5
    #config.add_facet_field solr_name("file_format", :facetable), label: "File Format", limit: 5

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field 'collection_name_ssim', :label => 'Collection'
    config.add_index_field 'institution_name_ssim', :label => 'Institution'
    config.add_index_field solr_name("creator", :stored_searchable), label: "Creator", itemprop: 'creator'
    #config.add_index_field 'date_start_tsim', :label => 'Date', :helper_method => :index_date_value
    config.add_index_field 'date_created_display_ssim', :label => 'Date'
    config.add_index_field 'date_issued_display_ssim', :label => 'Date'
    #config.add_index_field 'date_created_tesim', :label => 'Date'
    #config.add_index_field 'date_issued_tesim', :label => 'Date'


=begin
    config.add_show_field 'collection_name_ssim', :label => 'Collection'
    config.add_show_field 'institution_name_ssim', :label => 'Institution'
    config.add_show_field solr_name("creator", :stored_searchable), label: "Creator", itemprop: 'creator'
    config.add_show_field 'date_start_tsim', :label => 'Date', :helper_method => :index_date_value
=end

    config.global_search_fields = []
    #config.global_search_fields << solr_name("title", :stored_searchable)
    config.global_search_fields << 'title_tesim^20'
    config.global_search_fields << 'ident_tesi^20'
    config.global_search_fields << 'alternative_tesim^10'
    #config.global_search_fields << 'dta_altLabel_all_subject_tsim' #Seems Replaced By dta_subject_alt_searchable_tesim
    config.global_search_fields << 'institution_name_ssim^4'
    config.global_search_fields << 'collection_name_ssim^4'
    config.global_search_fields << 'description_tesim^6'
    config.global_search_fields << 'creator_tesim^8'
    config.global_search_fields << 'contributor_tesim^8'
    config.global_search_fields << 'genre_tesim^4'
    config.global_search_fields << 'publisher_tesim^4'
    config.global_search_fields << 'subject_geographic_tesim^8'
    config.global_search_fields << 'dta_subject_primary_searchable_tesim^8'
    config.global_search_fields << 'dta_subject_alt_searchable_tesim^6'
    config.global_search_fields << 'toc_tesim^2'
    config.global_search_fields << 'dta_ocr_tiv'



=begin
    config.add_index_field solr_name("title", :stored_searchable), label: "Title", itemprop: 'name'
    config.add_index_field solr_name("description", :stored_searchable), label: "Description", itemprop: 'description'
    config.add_index_field solr_name("tag", :stored_searchable), label: "Keyword", itemprop: 'keywords'
    config.add_index_field solr_name("subject", :stored_searchable), label: "Subject", itemprop: 'about'
    config.add_index_field solr_name("creator", :stored_searchable), label: "Creator", itemprop: 'creator'
    config.add_index_field solr_name("contributor", :stored_searchable), label: "Contributor", itemprop: 'contributor'
    config.add_index_field solr_name("publisher", :stored_searchable), label: "Publisher", itemprop: 'publisher'
    config.add_index_field solr_name("based_near", :stored_searchable), label: "Location", itemprop: 'contentLocation'
    config.add_index_field solr_name("language", :stored_searchable), label: "Language", itemprop: 'inLanguage'
    config.add_index_field solr_name("date_uploaded", :stored_searchable), label: "Date Uploaded", itemprop: 'datePublished'
    config.add_index_field solr_name("date_modified", :stored_searchable), label: "Date Modified", itemprop: 'dateModified'
    config.add_index_field solr_name("date_created", :stored_searchable), label: "Date Created", itemprop: 'dateCreated'
    config.add_index_field solr_name("rights", :stored_searchable), label: "Rights"
    config.add_index_field solr_name("resource_type", :stored_searchable), label: "Resource Type"
    config.add_index_field solr_name("format", :stored_searchable), label: "File Format"
    config.add_index_field solr_name("identifier", :stored_searchable), label: "Identifier"
=end

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
=begin
    config.add_show_field solr_name("title", :stored_searchable), label: "Title"
    config.add_show_field solr_name("description", :stored_searchable), label: "Description"
    config.add_show_field solr_name("tag", :stored_searchable), label: "Keyword"
    config.add_show_field solr_name("subject", :stored_searchable), label: "Subject"
    config.add_show_field solr_name("creator", :stored_searchable), label: "Creator"
    config.add_show_field solr_name("contributor", :stored_searchable), label: "Contributor"
    config.add_show_field solr_name("publisher", :stored_searchable), label: "Publisher"
    config.add_show_field solr_name("based_near", :stored_searchable), label: "Location"
    config.add_show_field solr_name("language", :stored_searchable), label: "Language"
    config.add_show_field solr_name("date_uploaded", :stored_searchable), label: "Date Uploaded"
    config.add_show_field solr_name("date_modified", :stored_searchable), label: "Date Modified"
    config.add_show_field solr_name("date_created", :stored_searchable), label: "Date Created"
    config.add_show_field solr_name("rights", :stored_searchable), label: "Rights"
    config.add_show_field solr_name("resource_type", :stored_searchable), label: "Resource Type"
    config.add_show_field solr_name("format", :stored_searchable), label: "File Format"
    config.add_show_field solr_name("identifier", :stored_searchable), label: "Identifier"
=end

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.
    #
    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.
    config.add_search_field('all_fields', label: 'All Text', include_in_advanced_search: false) do |field|
      #all_names = config.show_fields.values.map(&:field).join(" ")
      title_name = solr_name("title", :stored_searchable)

      #all_names += ' ' + ['dta_altLabel_all_subject_tsim', 'institution_name_ssim', 'collection_name_ssim'].join(" ")
      #all_names += ' ' + config.global_search_fields.join(" ")
      all_names = config.global_search_fields.join(" ")
      #puts 'All names is: ' + all_names
      field.solr_parameters = {
        qf: "#{all_names} file_format_tesim",
        pf: "#{title_name}"
      }
    end

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.
    # creator, title, description, publisher, date_created,
    # subject, language, resource_type, format, identifier, based_near,

  config.add_search_field('title') do |field|
=begin
    field.solr_parameters = {
        :"spellcheck.dictionary" => "title"
    }
=end
    solr_name = solr_name("title", :stored_searchable)
    field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
    }
  end

  config.add_search_field('description') do |field|
    field.label = "Description"
=begin
    field.solr_parameters = {
        :"spellcheck.dictionary" => "description"
    }
=end
    solr_name = solr_name("description", :stored_searchable)
    field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
    }
  end

  config.add_search_field('creator') do |field|
=begin
    field.solr_parameters = { :"spellcheck.dictionary" => "creator" }
=end
    solr_name = solr_name("creator", :stored_searchable)
    field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
    }
  end

  config.add_search_field('publisher') do |field|
=begin
    field.solr_parameters = {
        :"spellcheck.dictionary" => "publisher"
    }
=end
    solr_name = solr_name("publisher", :stored_searchable)
    field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
    }
  end

    config.add_search_field('people / organizations') do |field|
=begin
      field.solr_parameters = {
          :"spellcheck.dictionary" => "people / organizations"
      }
=end
      solr_name = "dta_other_subject_tesim"
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

  config.add_search_field('identifier') do |field|
    field.include_in_advanced_search = false
=begin
    field.solr_parameters = {
        :"spellcheck.dictionary" => "identifier"
    }
=end
    #solr_name = solr_name("id", :stored_searchable)
    solr_name = 'ident_tesi'
    field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
    }
  end






    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    # label is key, solr field is value

=begin
    config.add_sort_field 'score desc, title_tesim asc', :label => 'relevance'
    config.add_sort_field 'title_tesim asc, dta_sortable_date_dtsi asc', :label => 'title'
    config.add_sort_field 'dta_sortable_date_dtsi asc, title_tesim asc', :label => 'date (asc)'
    config.add_sort_field 'dta_sortable_date_dtsi desc, title_tesim asc', :label => 'date (desc)'
=end

    config.add_sort_field 'score desc, title_primary_ssort asc', :label => 'relevance'
    config.add_sort_field 'title_primary_ssort asc, dta_sortable_date_dtsi asc', :label => "title \u25B2"
    config.add_sort_field 'title_primary_ssort desc, dta_sortable_date_dtsi asc', :label => "title \u25BC"
    config.add_sort_field 'dta_sortable_date_dtsi asc, title_primary_ssort asc', :label => "date \u25B2"
    config.add_sort_field 'dta_sortable_date_dtsi desc, title_primary_ssort asc', :label => "date \u25BC"

=begin
    config.add_sort_field "score desc, #{uploaded_field} desc", label: "relevance"
    config.add_sort_field "#{uploaded_field} desc", label: "date uploaded \u25BC"
    config.add_sort_field "#{uploaded_field} asc", label: "date uploaded \u25B2"
    config.add_sort_field "#{modified_field} desc", label: "date modified \u25BC"
    config.add_sort_field "#{modified_field} asc", label: "date modified \u25B2"
=end


    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5
  end

  def institution_base_blacklight_config
    # don't show collection facet
    @skip_dta_limits_render = true
    blacklight_config.facet_fields['collection_name_ssim'].show = false
    blacklight_config.facet_fields['collection_name_ssim'].if = false

    blacklight_config.facet_fields['institution_name_ssim'].show = false
    blacklight_config.facet_fields['institution_name_ssim'].if = false

    #Needs to be fixed...
    blacklight_config.facet_fields['dta_dates_ssim'].show = false
    blacklight_config.facet_fields['dta_dates_ssim'].if = false

    # collapse remaining facets
    #blacklight_config.facet_fields['subject_facet_ssim'].collapse = true
    #blacklight_config.facet_fields['subject_geographic_ssim'].collapse = true
    #blacklight_config.facet_fields['date_facet_ssim'].collapse = true
    #blacklight_config.facet_fields['genre_basic_ssim'].collapse = true
  end

  def collection_base_blacklight_config
    @skip_dta_limits_render = true
    blacklight_config.facet_fields['collection_name_ssim'].show = false
    blacklight_config.facet_fields['collection_name_ssim'].if = false


=begin
    blacklight_config.facet_fields['institution_name_ssim'].show = true
    blacklight_config.facet_fields['institution_name_ssim'].if = true
    blacklight_config.facet_fields['institution_name_ssim'].collapse = false
=end


    blacklight_config.facet_fields['institution_name_ssim'].show = false
    blacklight_config.facet_fields['institution_name_ssim'].if = false


    #Needs to be fixed...
    blacklight_config.facet_fields['dta_dates_ssim'].show = false
    blacklight_config.facet_fields['dta_dates_ssim'].if = false
  end

  # displays values and pagination links for Format field
  def genre_facet
    @nav_li_active = 'explore'
    @facet_no_more_link = true

    @facet = blacklight_config.facet_fields['genre_ssim']
    @response = get_facet_field_response(@facet.key, params)
    @display_facet = @response.aggregations[@facet.key]

    @pagination = facet_paginator(@facet, @display_facet)

    render :full_browse_facet
  end

  def topic_facet
    @nav_li_active = 'explore'
    @facet_no_more_link = true

    @facet = blacklight_config.facet_fields['dta_all_subject_ssim']
    @response = get_facet_field_response(@facet.key, params)
    @display_facet = @response.aggregations[@facet.key]

    @pagination = facet_paginator(@facet, @display_facet)

    render :full_browse_facet
  end


end
