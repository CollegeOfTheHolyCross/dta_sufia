# encoding: utf-8
require 'rest_client'
require 'restclient/components'
require 'rack/cache'
require "net/http"

class GenericFile < ActiveFedora::Base
  include Sufia::GenericFile
  has_and_belongs_to_many :institutions, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isMemberOf, class_name: "Institution"
  contains "ocr"

  property :toc, predicate: ::RDF::Vocab::DC.tableOfContents, multiple: false do |index|
    index.as :stored_searchable
  end

  property :analog_format, predicate: ::RDF::Vocab::DC.format, multiple: false do |index|
    index.as :stored_searchable
  end
  
  property :digital_format, predicate: ::RDF::Vocab::DC11.format, multiple: false do |index|
    index.as :stored_searchable
  end
  
  property :temporal_coverage, predicate: ::RDF::Vocab::DC.temporal do |index|
    index.as :stored_searchable
  end
  
  property :date_issued, predicate: ::RDF::Vocab::DC.issued do |index|
    index.as :stored_searchable
  end
  #::RDF::SCHEMA.
  property :genre, predicate: ::RDF::Vocab::EDM.hasType do |index|
    index.as :stored_searchable, :symbol
  end
  
  property :alternative, predicate: ::RDF::Vocab::DC.alternative do |index|
    index.as :stored_searchable
  end

  #http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#adultContent is boolean only :(
  #FIXME: Both rights and flagged have multiple set to true and their forms generate with that...
  #FIXME: MULTIPLE SHOULD BE FALSE!!! Main page gives an error though if it is... ><
  property :flagged, predicate: ::RDF::URI.new('http://digitaltransgenderarchive.net/ns/flagged'), multiple: false do |index|
    index.as :stored_searchable
  end

  property :lcsh_subject, predicate: ::RDF::Vocab::DC.subject do |index|
    index.as :stored_searchable, :facetable, :symbol
  end

  property :other_subject, predicate: ::RDF::Vocab::DC.subject do |index|
    index.as :stored_searchable, :facetable, :symbol
  end

  property :homosaurus_subject, predicate: ::RDF::Vocab::DC.subject do |index|
    index.as :stored_searchable, :facetable, :symbol
  end

  property :is_shown_at, predicate: ::RDF::Vocab::EDM.isShownAt, multiple: false do |index|
    index.as :stored_searchable, :facetable, :symbol
  end

  property :preview, predicate: ::RDF::Vocab::EDM.preview, multiple: false do |index|
    index.as :stored_searchable, :facetable, :symbol
  end

  property :hosted_elsewhere, predicate: ::RDF::URI.new('http://digitaltransgenderarchive.net/ns/hosted_elsewhere'), multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  # For local items, mime_type seems to work. But seems like not setting mime_type correctly for items with no image originally.
  # Hosted elsewhere objects currently show as image/jp2...

  makes_derivatives do |obj|
    case obj.mime_type
      when *pdf_mime_types
        #obj.transform_file :content, thumbnail: { format: 'jpg', size: '338x493', datastream: 'thumbnail' }
        obj.thumbnail.delete
        ActiveFedora::Base.eradicate("#{obj.id}/thumbnail")

        img = MiniMagick::Image.read(obj.content.content)

        img.combine_options do |c|
          c.trim "+repage"
        end

        img.format 'jpg'
        img.resize '338x493'
        obj.thumbnail.content = img.to_blob
        obj.thumbnail.mime_type = 'image/jpeg'
        obj.thumbnail.original_name = obj.content.original_name.split('.').first + '.jpg'

          begin
            text_content = ''
            #Internet Archive Object
            if obj.identifier.present?
              ia_id = obj.identifier[0].split('/').last
              djvu_data_text_response = fetch("http://archive.org/download/#{ia_id}/#{ia_id}_djvu.txt")
              text_content = djvu_data_text_response.body.squish if djvu_data_text_response.body.present?
            else
              reader = PDF::Reader.new(StringIO.open(obj.content.content))

              text_content = []
              reader.pages.each do |page|
                text_content << page.text
              end
              text_content = text_content.join(" ").gsub(/\n/, ' ').gsub(/\uFFFF/, ' ').squish
            end

            obj.ocr.delete
            ActiveFedora::Base.eradicate("#{obj.id}/ocr")
            obj.ocr.content = text_content
            obj.ocr.mime_type = 'text/plain'
            obj.ocr.original_name = obj.content.original_name.split('.').first + '.txt'

          rescue PDF::Reader::MalformedPDFError => ex
            #Ignore this...malformed PDF. Might be able to patch as posted in:
            #https://groups.google.com/forum/#!topic/pdf-reader/e_Ba-myn584
          rescue => ex
            raise ex
          end
      when *office_document_mime_types
        obj.transform_file :content, { thumbnail: { format: 'jpg', size: '338x493', datastream: 'thumbnail' } }, processor: :document
      when *audio_mime_types
        obj.transform_file :content, { mp3: { format: 'mp3', datastream: 'mp3' }, ogg: { format: 'ogg', datastream: 'ogg' } }, processor: :audio
      when *video_mime_types
        obj.transform_file :content, { webm: { format: 'webm', datastream: 'webm' }, mp4: { format: 'mp4', datastream: 'mp4' }, thumbnail: { format: 'jpg', datastream: 'thumbnail' } }, processor: :video
      when *image_mime_types
        obj.transform_file :content, thumbnail: { format: 'jpg', size: '338x493', datastream: 'thumbnail' }
    end
  end

  def remove_collection

  end

  def lcsh_subject_label
    ['hello']
  end

  def audio?
    self.class.audio_mime_types.include? mime_type
  end

  def self.blazegraph_config
    @blazegraph_config ||= YAML::load(File.open(blazegraph_config_path))[env]
                               .with_indifferent_access
  end

  def self.app_root
    return @app_root if @app_root
    @app_root = Rails.root if defined?(Rails) and defined?(Rails.root)
    @app_root ||= APP_ROOT if defined?(APP_ROOT)
    @app_root ||= '.'
  end

  def self.env
    return @env if @env
    #The following commented line always returns "test" in a rails c production console. Unsure of how to fix this yet...
    #@env = ENV["RAILS_ENV"] = "test" if ENV
    @env ||= Rails.env if defined?(Rails) and defined?(Rails.root)
    @env ||= 'development'
  end

  def self.blazegraph_config_path
    File.join(app_root, 'config', 'blazegraph.yml')
  end

  def self.repo
    @repo ||= ::RDF::Blazegraph::Repository.new(GenericFile.blazegraph_config[:url])
  end

  def self.qskos value
    if value.match(/^sh\d+/)
      return ::RDF::URI.new("http://id.loc.gov/authorities/subjects/#{value}")
    else
      return ::RDF::URI.new("http://www.w3.org/2004/02/skos/core##{value}")
    end
  end

  def self.fetch(uri_str, limit = 10)
    # You should choose better exception.
    raise ArgumentError, 'HTTP redirect too deep' if limit == 0

    url = URI.parse(uri_str)
    req = Net::HTTP::Get.new(url.path, { 'User-Agent' => 'Mozilla/5.0 (etc...)' })
    response = Net::HTTP.start(url.host, url.port, :use_ssl => url.scheme == 'https') { |http| http.request(req) }
    case response
      when Net::HTTPSuccess     then response
      when Net::HTTPRedirection then fetch(response['location'], limit - 1)
      else
        response.error!
    end
  end

  def self.get_redirect(uri_str)
    # You should choose better exception.
    url = URI.parse(uri_str)
    req = Net::HTTP::Get.new(url.path, { 'User-Agent' => 'Mozilla/5.0 (etc...)' })
    response = Net::HTTP.start(url.host, url.port, :use_ssl => url.scheme == 'https') { |http| http.request(req) }
    case response
      when Net::HTTPRedirection then return response['location']
      else
        response.error!
    end
  end

  def to_solr(doc = {} )
    doc = super(doc)

    if self.ocr.present?
      doc['dta_ocr_tiv'] = self.ocr.content.squish
    end
    doc['identifier_ssim'] = self.identifier

    doc['ident_tesi'] = self.id

    doc['collection_name_ssim'] = []
    doc['institution_name_ssim'] = []

    doc['dta_homosaurus_subject_ssim'] = []
    doc['dta_lcsh_subject_ssim'] = []
    doc['dta_other_subject_ssim'] = []
    doc['dta_all_subject_ssim'] = []

    doc['dta_subject_primary_searchable_tesim'] = []
    doc['dta_subject_alt_searchable_tesim'] = []

    doc['dta_altLabel_all_subject_ssim'] = []

    doc['dta_dates_ssim'] = []
    doc['dta_sortable_date_dtsi'] = []

    doc['language_label_ssim'] = []

    doc['is_public_ssi'] = self.public?.to_s

    doc['title_primary_ssort'] = self.title.first

    doc['creator_ssim'] = self.creator
    doc['contributor_ssim'] = self.contributor

    self.collections.each do |collection|
      doc['collection_name_ssim'] << collection.title
      doc['collection_name_ssort'] = collection.title
      #collection.institutions.each do |institution|
        #doc['institution_name_ssim'] << institution.name
      #end
    end

    self.institutions.each do |institution|
      doc['primary_institution_ssi'] = institution.name
      doc['institution_name_ssim'] = [institution.name]
    end

    self.language.each do |lang|
      if lang.match(/eng$/)
        doc['language_label_ssim'] << 'English'
      end
    end


    self.subject.each do |subject|
      if subject.match(/http:\/\/homosaurus\.org\/terms\//)
        term = Homosaurus.find('homosaurus/terms/' + subject.split('/').last)
        doc['dta_homosaurus_subject_ssim'] << term.prefLabel
        doc['dta_all_subject_ssim'] << term.prefLabel
        term.altLabel.each do |alt|
          doc['dta_altLabel_all_subject_ssim'] << alt
        end

        #FIXME: Not doing alts currently...
      elsif subject.match(/http:\/\/id.loc.gov\/authorities\/subjects\//)
        english_label = nil
        default_label = nil
        any_match = nil
        full_alt_term_list = []

        if GenericFile.repo.query(:subject=>::RDF::URI.new(subject), :predicate=>GenericFile.qskos('prefLabel')).count > 0
          GenericFile.repo.query(:subject=>::RDF::URI.new(subject), :predicate=>GenericFile.qskos('prefLabel')).each_statement do |result_statement|
            #LoC has blank nodes... see alts of http://id.loc.gov/authorities/subjects/sh85102696 ... these aren't literals.
            #LoC's blank node representation.... alt: to_s == "_:t829213" or check .resource? or check .node? or .id == 't829213'
            if result_statement.object.literal?
              if result_statement.object.language == :en
                english_label ||= result_statement.object.value
              elsif result_statement.object.language.blank?
                default_label ||= result_statement.object.value
              else
                any_match ||= result_statement.object.value
                #FIXME
                full_alt_term_list << result_statement.object.value
              end
            end
          end

          default_label ||= any_match
          english_label ||= default_label
          doc['dta_lcsh_subject_ssim'] << english_label
          doc['dta_all_subject_ssim'] << english_label

          #FIXME
          #sleep(1.0)
        else
          doc['dta_lcsh_subject_ssim'] << subject
          doc['dta_all_subject_ssim'] << subject
        end

        GenericFile.repo.query(:subject=>::RDF::URI.new(subject), :predicate=>GenericFile.qskos('altLabel')).each_statement do |result_statement|
          full_alt_term_list << result_statement.object.value if result_statement.object.literal?
        end

        doc['dta_altLabel_all_subject_ssim'] += full_alt_term_list

      else
        doc['dta_other_subject_ssim'] << subject
        #doc['dta_all_subject_ssim'] << subject

      end
    end

    doc['dta_altLabel_all_subject_ssim'].uniq!

    doc['dta_homosaurus_subject_ssim'].sort_by!{|word| word.downcase}
    doc['dta_all_subject_ssim'].sort_by!{|word| word.downcase}
    doc['dta_lcsh_subject_ssim'].sort_by!{|word| word.downcase}
    doc['dta_other_subject_ssim'].sort_by!{|word| word.downcase}

    doc['dta_other_subject_tesim'] = doc['dta_other_subject_ssim']
    doc['dta_subject_primary_searchable_tesim'] = doc['dta_all_subject_ssim'] + doc['dta_other_subject_ssim']
    doc['dta_subject_alt_searchable_tesim'] = doc['dta_altLabel_all_subject_ssim']


    self.date_issued.each do |raw_date|
      date = Date.edtf(raw_date)
      if date.class == Date
        doc['date_start_dtsi'] = date.year.to_s + '-01-01T00:00:00.000Z'
        doc['date_end_dtsi'] = date.year.to_s + '-01-01T00:00:00.000Z'
        doc['dta_dates_ssim'] << date.year
        doc['dta_sortable_date_dtsi'] = date.year.to_s + '-01-01T00:00:00.000Z'
      elsif date.present?
        doc['date_start_dtsi'] = date.first.year.to_s + '-01-01T00:00:00.000Z'
        doc['date_end_dtsi'] = date.last.year.to_s + '-01-01T00:00:00.000Z'
        doc['dta_sortable_date_dtsi'] = (((date.last.year.to_i - date.first.year.to_i) / 2) + date.first.year.to_i).to_i.to_s + '-01-01T00:00:00.000Z'
        (date.first.year..date.last.year).step(1) do |year_step|
          doc['dta_dates_ssim'] << year_step
        end
      end
    end

    self.date_created.each do |raw_date|
      date = Date.edtf(raw_date)
      if date.class == Date
        doc['date_start_dtsi'] = date.year.to_s + '-01-01T00:00:00.000Z'
        doc['date_end_dtsi'] = date.year.to_s + '-01-01T00:00:00.000Z'
        doc['dta_dates_ssim'] << date.year
        doc['dta_sortable_date_dtsi'] = date.year.to_s + '-01-01T00:00:00.000Z'
      elsif date.present?
        doc['date_start_dtsi'] = date.first.year.to_s + '-01-01T00:00:00.000Z'
        doc['date_end_dtsi'] = date.last.year.to_s + '-01-01T00:00:00.000Z'
        doc['dta_sortable_date_dtsi'] = (((date.last.year.to_i - date.first.year.to_i) / 2) + date.first.year.to_i).to_i.to_s + '-01-01T00:00:00.000Z'
        (date.first.year..date.last.year).step(1) do |year_step|
          doc['dta_dates_ssim'] << year_step
        end
      end
    end

    #doc['dta_sortable_date_dtsi'] = [doc['dta_sortable_date_dtsi'].first] if doc['dta_sortable_date_dtsi'].present?

    doc['based_near_ssim'] = self.based_near if self.based_near.present?

    doc['subject_geojson_facet_ssim'] = []
    doc['subject_geographic_ssim'] = []
    doc['subject_geographic_tesim'] = []
    doc['subject_coordinates_geospatial'] = []
    doc['subject_geographic_hier_ssim'] = []


    #NEED TO ADD THE FOLLOWING AFTER coordinate in schema.xml:

=begin
    <!-- Solr4 geospatial field for coordinates, shapes, etc. -->
        <dynamicField name="*_geospatial" type="location_rpt"  indexed="true" stored="true"  multiValued="true" />
=end


    self.based_near.each do |spatial|
      geojson_hash_base = {type: 'Feature', geometry: {type: 'Point'}}

      r = RestClient.get 'http://api.geonames.org/getJSON', {:params => {:geonameId=>"#{spatial.split('/').last}", :username=>"boston_library"}, accept: :json}
      result = JSON.parse(r)

      geojson_hash_base[:geometry][:coordinates] = [result['lng'],result['lat']]
      doc['subject_coordinates_geospatial'] << "#{result['lat']},#{result['lng']}"


      if result['fcl'] == 'P' and result['adminCode1'].present?
        #geojson_hash_base[:properties] = {placename: result['name'] + ', ' + result['adminCode1']}
        geojson_hash_base[:properties] = {placename: result['name']}
      else
        geojson_hash_base[:properties] = {placename: result['name']}
      end

      doc['subject_geographic_ssim'] << result['name']
      doc['subject_geographic_ssim'] << result['adminName1'] if result['adminName1'].present?
      doc['subject_geographic_ssim'] << result['adminName2'] if result['adminName2'].present?
      doc['subject_geographic_ssim'] << result['adminName3'] if result['adminName3'].present?
      doc['subject_geographic_ssim'] << result['countryName'] if result['countryName'].present?

      doc['subject_geojson_facet_ssim'].append(geojson_hash_base.to_json)

      hier_result = []
      hier_result << result['adminName1'] if result['adminName1'].present?
      hier_result << result['adminName2'] if result['adminName2'].present?
      hier_result << result['adminName3'] if result['adminName3'].present?
      hier_result << result['name']

      hier_result.uniq!
      doc['subject_geographic_hier_ssim'] << hier_result.join('||')
    end

    doc['subject_geographic_ssim'].uniq!
    doc['subject_geographic_tesim'] = doc['subject_geographic_ssim']


    doc



  end
end