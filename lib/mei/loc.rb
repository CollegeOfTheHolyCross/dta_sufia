require 'uri'

module Mei
  class Loc

    include Mei::WebServiceBase

    def initialize(subauthority)
      @subauthority = subauthority
    end

    def search q
      @raw_response = get_json(build_query_url(q))
      parse_authority_response
    end


    def build_query_url q
      escaped_query = URI.escape(q)
      authority_fragment = Qa::Authorities::Loc.get_url_for_authority(@subauthority) + URI.escape(@subauthority)
      return "http://id.loc.gov/search/?q=#{escaped_query}&q=#{authority_fragment}&format=json"
    end

    # Reformats the data received from the LOC service
    def parse_authority_response
      threaded_responses = []
      #end_response = Array.new(20)
      end_response = []
      position_counter = 0
      @raw_response.select {|response| response[0] == "atom:entry"}.map do |response|
        threaded_responses << Thread.new(position_counter) { |local_pos|
          end_response[local_pos] = loc_response_to_qa(response_to_struct(response))
        }
        position_counter+=1
        sleep(0.15)
        #loc_response_to_qa(response_to_struct(response))
      end
      threaded_responses.each { |thr|  thr.join }
      end_response
    end

    # Simple conversion from LoC-based struct to QA hash
    def loc_response_to_qa data
      json_link = data.links.select { |link| link.first == 'application/json' }
      if json_link.present?
        json_link = json_link[0][1]
        puts 'Json Link is: ' + json_link
        item_response = get_json(json_link)
        broader, narrower, variants = get_skos_concepts(item_response)
      end

      #count = ActiveFedora::Base.find_with_conditions("subject_tesim:#{data.id.gsub('info:lc', 'http://id.loc.gov').gsub(':','\:')}", rows: '100', fl: 'id' ).length
      #FIXME
      count = ActiveFedora::Base.find_with_conditions("lcsh_subject_ssim:#{solr_clean(data.id.gsub('info:lc', 'http://id.loc.gov'))}", rows: '100', fl: 'id' ).length

      if count >= 99
        count = "99+"
      else
        count = count.to_s
      end



      {
          "uri_link" => data.id.gsub('info:lc', 'http://id.loc.gov') || data.title,
          "label" => data.title,
          "broader" => broader,
          "narrower" => narrower,
          "variants" => variants,
          "count" => count
      }
    end


    def solr_clean(term)
      return term.gsub('\\', '\\\\').gsub(':', '\\:').gsub(' ', '\ ')
    end

    def response_to_struct response
      result = response.each_with_object({}) do |result_parts, result|
        next unless result_parts[0]
        key = result_parts[0].sub('atom:', '').sub('dcterms:', '')
        info = result_parts[1]
        val = result_parts[2]

        case key
          when 'title', 'id', 'name', 'updated', 'created'
            result[key] = val
          when 'link'
            result["links"] ||= []
            result["links"] << [info["type"], info["href"]]
        end
      end

      OpenStruct.new(result)
    end

    def get_skos_concepts response
      broader_list = []
      narrower_list = []
      variant_list = []

      response.each do |resp|
        if resp.has_key?("http://www.loc.gov/mads/rdf/v1#hasBroaderAuthority")
          resp["http://www.loc.gov/mads/rdf/v1#hasBroaderAuthority"].each do |broader|
            if broader["@id"].present?
              broader_uri = broader["@id"]

              broader_label = response.select { |broader_resp| broader_resp["@id"] == broader_uri and broader_resp.has_key?("http://www.loc.gov/mads/rdf/v1#authoritativeLabel") and !broader_resp.has_key?("http://www.loc.gov/mads/rdf/v1#elementList") }
              broader_label = broader_label[0]["http://www.loc.gov/mads/rdf/v1#authoritativeLabel"][0]["@value"]

              broader_list << {:uri_link=>broader_uri, :label=>broader_label}
            end
          end
        end
        if resp.has_key?("http://www.loc.gov/mads/rdf/v1#hasNarrowerAuthority")
          resp["http://www.loc.gov/mads/rdf/v1#hasNarrowerAuthority"].each do |narrower|
            if narrower["@id"].present?
              narrower_uri = narrower["@id"]


              narrower_label = response.select { |narrower_resp| narrower_resp["@id"] == narrower_uri and narrower_resp.has_key?("http://www.loc.gov/mads/rdf/v1#authoritativeLabel") and !narrower_resp.has_key?("http://www.loc.gov/mads/rdf/v1#elementList") }
              narrower_label = narrower_label[0]["http://www.loc.gov/mads/rdf/v1#authoritativeLabel"][0]["@value"]

              narrower_list << {:uri_link=>narrower_uri, :label=>narrower_label}
            end

          end

        end

        if resp.has_key?("http://www.loc.gov/mads/rdf/v1#variantLabel")
          resp["http://www.loc.gov/mads/rdf/v1#variantLabel"].each do |variant|
            if variant["@value"].present?
              varient_label = variant["@value"]
=begin
              if variant["@language"].present?
                varient_label += "@#{variant["@language"]}"
              end
=end

              variant_list << varient_label
            end

          end

        end
      end

      return broader_list, narrower_list, variant_list
    end
  end
end