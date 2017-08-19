# encoding: utf-8
require 'zip'
require "net/http"
require "uri"

module Harvard
  class HarvardBooks
    @queue = :internet_archive

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

    def self.perform(*args)
      args = args.first
      @upload_collection_id = args["collection_id"]
      @upload_institution_id = args["institution_id"]

      @depositor = args["depositor"]

      @start = 0
      @step = 250
      @end_val = 9999999
      #@url = "http://archive.org/advancedsearch.php?q=collection%3A%22#{collection_id}%22&fl%5B%5D=identifier&output=json&rows=10000"

      while @end_val >= @start do
      @url = "https://api.lib.harvard.edu/v2/items.json?q=mc614%2520demaios&physicalLocation=Schlesinger&limit=#{@step}&start=#{@start}"
      @url = "https://api.lib.harvard.edu/v2/items?q=mc614%2520demaios&physicalLocation=Schlesinger&limit=#{@step}&start=#{@start}"

      list_response = Typhoeus::Request.get(@url, ssl_verifypeer: false)
      response_xml = Nokogiri::XML(list_response.body)
      response_xml.remove_namespaces!

      @end_val =  response_xml.xpath("//numFound").text.to_i
      @start = @start + @step

      response_xml.xpath("//mods").each do |record_meta_xml|
        @record_meta_xml = record_meta_xml
        @collection = ActiveFedora::Base.find(@upload_collection_id)
        @institution = ActiveFedora::Base.find(@upload_institution_id)
        retry_count = 0
        @harvard_id = @record_meta_xml.xpath(".//recordIdentifier[@source='MH:VIA']").text.split("_").first
        show_location = "https://id.lib.harvard.edu/images/#{@harvard_id}/catalog"
        full_escaped_uri = solr_clean(show_location)
        solr_response = GenericFile.find_with_conditions("identifier_ssim:#{full_escaped_uri}", rows: '25', fl: 'id' )
        if solr_response.blank?

          @generic_file = ::GenericFile.new
          @generic_file.depositor = @depositor
          @generic_file.permissions_attributes = [{ type: 'group', name: 'public', access: 'read' }, {type: 'group', name: 'admin', access: 'edit'}, {type: 'group', name: 'superuser', access: 'edit'}]
          @generic_file.edit_users += [@depositor]

          main_title = nil
          alternative_titles = []
          @record_meta_xml.xpath("./titleInfo/title").each do |title_element|
            if main_title.blank?
              main_title = title_element.text
            else
              alternative_titles << title_element.text
            end
          end

          @generic_file.title = [main_title]
          @generic_file.alternative = alternative_titles if alternative_titles.present?
          @generic_file.label = main_title
          @generic_file.identifier = [show_location]
          #@generic_file.ocr = djvu_data_text.to_s.force_encoding("UTF-8")
          @generic_file.hosted_elsewhere = "1"
          @generic_file.is_shown_at = show_location

          @generic_file.resource_type << @record_meta_xml.xpath(".//typeOfResource").text

          @record_meta_xml.xpath(".//subject").each do |subject_element|
            solr_response = Homosaurus.find_with_conditions("dta_homosaurus_lcase_prefLabel_ssi:#{solr_clean(subject_element.text.downcase)}", rows: '25', fl: 'identifier_ssi, prefLabel_ssim, altLabel_ssim, narrower_ssim, broader_ssim, related_ssim' )
            if solr_response.present? and solr_response.count == 1
              @generic_file.homosaurus_subject += ['http://homosaurus.org/terms/' + solr_response.first['identifier_ssi']]
            elsif  solr_response.present? and solr_response.count > 1
              raise "Solr count mismatch for " + ia_id
            else
              authority_check = Mei::Loc.new('subjects')
              authority_result = authority_check.search(subject_element.text) #URI escaping doesn't work for Baseball fields?
              if authority_result.present?
                authority_result = authority_result.select{|hash| hash['label'].downcase == subject_element.text.downcase }
                if  authority_result.present?
                  @generic_file.homosaurus_subject += [authority_result.first["id"].gsub('info:lc', 'http://id.loc.gov')]
                else
                  raise "No homosaurus or LCSH match for " + ia_id
                end
              end
            end
          end

          date_text = @record_meta_xml.xpath(".//dateOther[@keyDate='yes']").text.gsub('-','/')
          date_text = '1977~' if date_text == 'circa 1977'
          date_text = '1985/1989' if date_text == 'between 1985 and 1989'
          date_text = '1980?/1989?' if date_text == '1980sca.'
          date = Date.edtf(date_text)

          if date.present?
            @generic_file.date_created = date.to_s
          else
            raise "Could not parse date for: " + @record_meta_xml.xpath(".//dateOther[@keyDate='yes']").text
          end

          type_of_resource = Sufia.config.resource_types.keys.select { |item| item.downcase == @record_meta_xml.xpath(".//typeOfResource").text.downcase }
          if genre.present?
            @generic_file.analog_format = type_of_resource.first
          else
            railse "Could not find type of resource for #{@record_meta_xml.xpath(".//typeOfResource").text}"
          end

          genre = Sufia.config.genre_list.keys.select { |item| item.downcase == @record_meta_xml.xpath(".//genre").text.downcase }
          if genre.present?
            @generic_file.genre = genre
          else
            railse "Could not find genre for #{@record_meta_xml.xpath(".//genre").text}"
          end

          @record_meta_xml.xpath(".//note").each do |description_element|
            @generic_file.description += [description_element.text] if description_element.present? and !description_element.text.include?('General note:')
          end

          @record_meta_xml.xpath('.//relatedItem[displayLabel="part of"').each do |description_element|
            @generic_file.description += ['Part of ' + description_element.text] if description_element.present?
          end

          @record_meta_xml.xpath(".//accessCondition").each do |access_condition|
            @generic_file.rights_free_text += [access_condition.text] if access_condition.present?
          end
          @generic_file.rights = ["Contact host institution for more information"]


          time_in_utc = DateTime.now.new_offset(0)
          @generic_file.date_uploaded = time_in_utc
          @generic_file.date_modified = time_in_utc
          @generic_file.visibility = 'restricted'


          begin

              image_path = @record_meta_xml.xpath('.//url[@displayLabel="Full Image"]').text
              image_path ||= @record_meta_xml.xpath('.//url[@displayLabel="Thumbnail"]').text
              img = MiniMagick::Image.open(image_path) do |b|
                b.format "jpg"
                b.resize "500x600>"
              end

              @generic_file.add_file(StringIO.open(img.to_blob), path:  'content', mime_type: 'image/jpeg')

              @generic_file.add_file(StringIO.open(djvu_data_text), path:  'ocr', mime_type: 'text/plain')


              @generic_file.save

              acquire_lock_for(@upload_collection_id) do
                collection = ::Collection.find(@upload_collection_id)
                collection.add_members [@generic_file.id]
                collection.save
              end

              acquire_lock_for(@upload_institution_id) do
                institution = ::Institution.find(@upload_institution_id)
                institution.files << ActiveFedora::Base.find([@generic_file.id])
                institution.save
              end

              @generic_file.reload
              @generic_file.update_index

              Sufia.queue.push(CharacterizeJob.new(@generic_file.id))

          rescue => error
            retry_count += 1
            sleep(5)
            retry if retry_count < 4
            current_error = "Either image is corrupt, derivatives broken, or relationships not being set right for #{show_url} \n"
            current_error += "Error message: #{error.message}\n"
            current_error += "Error backtrace: #{error.backtrace}\n"
            raise(current_error)
          end

end
        end
      end
    end

    def self.acquire_lock_for(lock_key, &block)
      lock_manager.lock(lock_key, &block)
    end

    def self.lock_manager
      @lock_manager ||= Sufia::LockManager.new(
          Sufia.config.lock_time_to_live,
          Sufia.config.lock_retry_count,
          Sufia.config.lock_retry_delay)
    end

    def self.solr_clean(term)
      return term.gsub('\\', '\\\\').gsub(':', '\\:').gsub(' ', '\ ')
    end

  end
end