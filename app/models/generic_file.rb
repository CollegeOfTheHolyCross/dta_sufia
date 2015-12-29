require 'rest_client'
require 'restclient/components'
require 'rack/cache'

class GenericFile < ActiveFedora::Base
  include Sufia::GenericFile
  
  property :analog_format, predicate: ::RDF::DC.format, multiple: false do |index|
    index.as :stored_searchable
  end
  
  property :digital_format, predicate: ::RDF::DC11.format, multiple: false do |index|
    index.as :stored_searchable
  end
  
  property :temporal_coverage, predicate: ::RDF::DC.temporal do |index|
    index.as :stored_searchable
  end
  
  property :date_issued, predicate: ::RDF::DC.issued do |index|
    index.as :stored_searchable
  end
  #::RDF::SCHEMA.
  property :genre, predicate: ::RDF::Vocab::EDM.hasType do |index|
    index.as :stored_searchable
  end
  
  property :alternative, predicate: ::RDF::DC.alternative do |index|
    index.as :stored_searchable
  end

  #http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#adultContent is boolean only :(
  #FIXME: Both rights and flagged have multiple set to true and their forms generate with that...
  #FIXME: MULTIPLE SHOULD BE FALSE!!! Main page gives an error though if it is... ><
  property :flagged, predicate: ::RDF::URI.new('http://digitaltransgenderarchive.net/ns/flagged'), multiple: false do |index|
    index.as :stored_searchable
  end

  property :lcsh_subject, predicate: ::RDF::DC.subject do |index|
    index.as :stored_searchable, :facetable, :symbol
  end

  property :other_subject, predicate: ::RDF::DC.subject do |index|
    index.as :stored_searchable, :facetable, :symbol
  end

  property :homosaurus_subject, predicate: ::RDF::DC.subject do |index|
    index.as :stored_searchable, :facetable, :symbol
  end

  def lcsh_subject_label
    ['hello']
  end

  def to_solr(doc = {} )
    doc = super(doc)

    doc['collection_name_ssim'] = []
    doc['institution_name_ssim'] = []
    doc['dta_homosaurus_subject_ssim'] = []
    doc['dta_lcsh_subject_ssim'] = []
    doc['dta_other_subject_ssim'] = []
    doc['dta_all_subject_ssim'] = []
    doc['dta_altLabel_all_subject_ssim'] = []

    doc['dta_dates_ssim'] = []

    self.collections.each do |collection|
      doc['collection_name_ssim'] << collection.title
      collection.institutions.each do |institution|
        doc['institution_name_ssim'] << institution.name
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
#http://www.geonames.org/5391959
        #r = RestClient.get 'http://api.geonames.org/getJSON', {:params => {:geonameId=>"5391959", :username=>"boston_library"}, accept: :json}
        #result = JSON.parse(r)


        #/proxy?q=http://digitaltransgenderarchive.xyz/raw_proxy?q=<subject>.json

=begin
        label_holder = nil
        any_match = nil
        RestClient.enable Rack::Cache
        r = RestClient.get "/proxy?q=http://digitaltransgenderarchive.xyz/proxy?q=#{subject}.json", { accept: :json }
        RestClient.disable Rack::Cache
        JSON.parse(r).first['http://www.w3.org/2004/02/skos/core#prefLabel'].each do |lcsh_label|
          if !lcsh_label.has_key?('@language') || (lcsh_label.has_key?('@language') && lcsh_label['@language'] == 'en')
            label_holder ||= lcsh_label['@value']
          else
            any_match ||= lcsh_label['@value']
          end
        end
        label_holder ||= any_match
        doc['dta_lcsh_subject_ssim'] << label_holder
        doc['dta_all_subject_ssim'] << label_holder
=end

        label_holder = nil
        any_match = nil
        RestClient.enable Rack::Cache
        begin
        r = RestClient.get  "/proxy_raw?q=http://digitaltransgenderarchive.xyz/proxy_raw?q=#{subject}.json", { accept: :json }
        rescue
          raise 'subject was: ' + subject
        end
        RestClient.disable Rack::Cache
        result = JSON.parse(r)
        #FIXME!!!
        if result['http://www.w3.org/2004/02/skos/core#prefLabel'].present?
          result.first['http://www.w3.org/2004/02/skos/core#prefLabel'].each do |lcsh_label|
            if !lcsh_label.has_key?('@language') || (lcsh_label.has_key?('@language') && lcsh_label['@language'] == 'en')
              label_holder ||= lcsh_label['@value']
            else
              any_match ||= lcsh_label['@value']
            end
          end
          label_holder ||= any_match
          doc['dta_lcsh_subject_ssim'] << label_holder
          doc['dta_all_subject_ssim'] << label_holder
        else
          doc['dta_lcsh_subject_ssim'] << subject
          doc['dta_all_subject_ssim'] << subject
        end


=begin
        label_holder = nil
        any_match = nil
        RestClient.enable Rack::Cache
        r = RestClient.get "#{subject}.json", { accept: :json }
        RestClient.disable Rack::Cache
        result = JSON.parse(r)
        #FIXME!!!
        if result['http://www.w3.org/2004/02/skos/core#prefLabel'].present?
          result.first['http://www.w3.org/2004/02/skos/core#prefLabel'].each do |lcsh_label|
            if !lcsh_label.has_key?('@language') || (lcsh_label.has_key?('@language') && lcsh_label['@language'] == 'en')
              label_holder ||= lcsh_label['@value']
            else
              any_match ||= lcsh_label['@value']
            end
          end
          label_holder ||= any_match
          doc['dta_lcsh_subject_ssim'] << label_holder
          doc['dta_all_subject_ssim'] << label_holder
        else
          doc['dta_lcsh_subject_ssim'] << subject
          doc['dta_all_subject_ssim'] << subject
        end
=end


      else
        doc['dta_other_subject_ssim'] << subject
        #doc['dta_all_subject_ssim'] << subject

      end
    end

    self.date_issued.each do |raw_date|
      date = Date.edtf(raw_date)
      if date.class == Date
        doc['dta_dates_ssim'] << date.year
      else
        (date.first.year..date.last.year).step(1) do |year_step|
          doc['dta_dates_ssim'] << year_step
        end
      end
    end

    self.date_created.each do |raw_date|
      date = Date.edtf(raw_date)
      if date.class == Date
        doc['dta_dates_ssim'] << date.year
      else
        (date.first.year..date.last.year).step(1) do |year_step|
          doc['dta_dates_ssim'] << year_step
        end
      end
    end

    doc['subject_geojson_facet_ssim'] = []
    doc['subject_geographic_ssim'] = []
    doc['subject_coordinates_geospatial'] = []


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
    end

    doc['subject_geographic_ssim'].uniq!


    doc



  end
end