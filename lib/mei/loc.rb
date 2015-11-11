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
      @raw_response.select {|response| response[0] == "atom:entry"}.map do |response|
        loc_response_to_qa(response_to_struct(response))
      end
    end

    # Simple conversion from LoC-based struct to QA hash
    def loc_response_to_qa data
      json_link = data.links.select { |link| link.first == 'application/json' }
      if json_link.present?
        json_link = json_link[0][1]
        puts 'Json Link is: ' + json_link
        item_response = get_json(json_link)
        broader, narrower = get_skos_concepts(item_response)
      end

      #count = ActiveFedora::Base.find_with_conditions("subject_tesim:#{data.id.gsub('info:lc', 'http://id.loc.gov').gsub(':','\:')}", rows: '100', fl: 'id' ).length
      #FIXME
      count = ActiveFedora::Base.find_with_conditions("subject_tesim:*#{data.id.split('/').last}", rows: '100', fl: 'id' ).length

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
          "count" => count
      }
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
      response.each do |resp|
        if resp.has_key?("http://www.loc.gov/mads/rdf/v1#hasBroaderAuthority")
          resp["http://www.loc.gov/mads/rdf/v1#hasBroaderAuthority"].each do |broader|
            broader_uri = broader["@id"]

            broader_label = response.select { |broader_resp| broader_resp["@id"] == broader_uri and broader_resp.has_key?("http://www.loc.gov/mads/rdf/v1#authoritativeLabel") and !broader_resp.has_key?("http://www.loc.gov/mads/rdf/v1#elementList") }
            broader_label = broader_label[0]["http://www.loc.gov/mads/rdf/v1#authoritativeLabel"][0]["@value"]

            broader_list << {:uri_link=>broader_uri, :label=>broader_label}
          end
        end
        if resp.has_key?("http://www.loc.gov/mads/rdf/v1#hasNarrowerAuthority")
          resp["http://www.loc.gov/mads/rdf/v1#hasNarrowerAuthority"].each do |narrower|
            narrower_uri = narrower["@id"]

            narrower_label = response.select { |narrower_resp| narrower_resp["@id"] == narrower_uri and narrower_resp.has_key?("http://www.loc.gov/mads/rdf/v1#authoritativeLabel") and !narrower_resp.has_key?("http://www.loc.gov/mads/rdf/v1#elementList") }
            narrower_label = narrower_label[0]["http://www.loc.gov/mads/rdf/v1#authoritativeLabel"][0]["@value"]

            narrower_list << {:uri_link=>narrower_uri, :label=>narrower_label}
          end

        end
      end

      return broader_list, narrower_list
    end
  end
end