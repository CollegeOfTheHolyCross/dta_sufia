# encoding: utf-8
require 'zip'
require "net/http"
require "uri"

module Harvard
  class HarvardSingleBook
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
      @record_meta_xml = Nokogiri::XML(args["metadata"])
      retry_count = 0


      @collection = ActiveFedora::Base.find(@upload_collection_id)
      @institution = ActiveFedora::Base.find(@upload_institution_id)

      @harvard_id = @record_meta_xml.xpath(".//recordIdentifier[@source='MH:VIA']").text.strip.split("_").first
      show_location = "http://id.lib.harvard.edu/images/#{@harvard_id}/catalog"
      full_escaped_uri = solr_clean(show_location)
      solr_response = GenericFile.find_with_conditions("identifier_ssim:#{full_escaped_uri}", rows: '25', fl: 'id' )
      if solr_response.present?
        raise "Duplicate for #{show_location}. This id is #{solr_response.first["id"]}. This full id is: #{@record_meta_xml.xpath(".//recordIdentifier[@source='MH:VIA']").text.strip}"
      elsif solr_response.blank?

        @generic_file = ::GenericFile.new
        @generic_file.depositor = @depositor
        @generic_file.permissions_attributes = [{ type: 'group', name: 'public', access: 'read' }, {type: 'group', name: 'admin', access: 'edit'}, {type: 'group', name: 'superuser', access: 'edit'}]
        @generic_file.edit_users += [@depositor]

        main_title = nil
        alternative_titles = []
        @record_meta_xml.xpath("./mods/titleInfo/title").each do |title_element|
          if main_title.blank?
            main_title = title_element.text.strip
          else
            alternative_titles << title_element.text.strip
          end
        end

        @generic_file.title = [main_title]
        @generic_file.alternative = alternative_titles if alternative_titles.present?
        @generic_file.label = main_title
        @generic_file.identifier = [show_location]
        #@generic_file.ocr = djvu_data_text.to_s.force_encoding("UTF-8")
        @generic_file.hosted_elsewhere = "1"
        @generic_file.is_shown_at = show_location

        #@generic_file.resource_type << @record_meta_xml.xpath(".//typeOfResource").text.strip

        @record_meta_xml.xpath("//subject").each do |subject_element|
          if subject_element.text.strip.downcase == 'group portraits'
            @generic_file.homosaurus_subject += ['http://id.loc.gov/authorities/subjects/sh85105182']
          elsif subject_element.text.strip.downcase == 'flowers (plants)'
              @generic_file.homosaurus_subject += ['http://id.loc.gov/authorities/subjects/sh85049332']
          elsif subject_element.text.strip.downcase == 'banjos'
            @generic_file.homosaurus_subject += ['http://id.loc.gov/authorities/subjects/sh85011545']
          elsif subject_element.text.strip.downcase == 'wedding dresses'
            #@generic_file.homosaurus_subject += ['wedding dresses']
          elsif subject_element.text.strip.downcase == 'costumes'
            @generic_file.homosaurus_subject += ['http://id.loc.gov/authorities/subjects/sh85033238']
          elsif subject_element.text.strip.downcase == 'meals'
            #@generic_file.homosaurus_subject += ['meals']
          elsif subject_element.text.strip.downcase == 'guitars'
            @generic_file.homosaurus_subject +=  ['http://id.loc.gov/authorities/subjects/sh85057803']
          elsif subject_element.text.strip.downcase == 'dressing rooms'
            @generic_file.homosaurus_subject +=  ['http://id.loc.gov/authorities/subjects/sh94005982']
          elsif subject_element.text.strip.downcase == 'beach grass'
            #skip
          elsif subject_element.text.strip.downcase == 'violins'
            @generic_file.homosaurus_subject += ['http://id.loc.gov/authorities/subjects/sh85143544']
          elsif subject_element.text.strip.downcase == 'steps'
            # This is stairs
            @generic_file.homosaurus_subject += ['http://id.loc.gov/authorities/subjects/sh85127267']
          else

          solr_response = Homosaurus.find_with_conditions("dta_homosaurus_lcase_prefLabel_ssi:#{solr_clean(subject_element.text.strip.downcase)}", rows: '25', fl: 'identifier_ssi, prefLabel_ssim, altLabel_ssim, narrower_ssim, broader_ssim, related_ssim' ) unless subject_element.text.strip.include?('(')
          if solr_response.present? and solr_response.count == 1
            @generic_file.homosaurus_subject += ['http://homosaurus.org/terms/' + solr_response.first['identifier_ssi']]
          elsif  solr_response.present? and solr_response.count > 1
            raise "Solr count mismatch for " + @harvard_id
          else
            authority_check = Mei::Loc.new('subjects')
            authority_result = authority_check.search(subject_element.text.strip) #URI escaping doesn't work for Baseball fields?
            if authority_result.present?
              authority_result = authority_result.select{|hash| hash['label'].downcase == subject_element.text.strip.downcase }
              if  authority_result.present?
                @generic_file.homosaurus_subject += [authority_result.first["uri_link"].gsub('info:lc', 'http://id.loc.gov')]
              else
                raise "No homosaurus or LCSH match for " + @harvard_id + " for subject value: " + subject_element.text.strip
              end
            end
          end
          end
        end

        date_text = @record_meta_xml.xpath(".//dateOther[@keyDate='yes']").text.strip.gsub('-','/')
        date_text = '1977~' if date_text == 'circa 1977' || date_text == 'ca. 1977'
        date_text = '1985/1989' if date_text == 'between 1985 and 1989'
        date_text = '1980?/1989?' if date_text == '1980sca.' || date_text == 'ca. 1980s'
        date_text = '1974~' if date_text == 'circa 1974' || date_text == 'ca. 1974'
        date_text = '1980/1984' if date_text == '1980 / 1984'
        date_text = '1986~' if date_text == 'circa 1986'
        date_text = '1985~' if date_text == 'ca. 1985' || date_text == 'circa 1985'
        date = Date.edtf(date_text)

        if date.present?
          @generic_file.date_created = [date.to_s]
        elsif date_text.present?
          raise "Could not parse date for: " + @record_meta_xml.xpath(".//dateOther[@keyDate='yes']").text.strip
        end

        type_of_resource = Sufia.config.resource_types.keys.select { |item| item.downcase == @record_meta_xml.xpath(".//typeOfResource").text.strip.downcase }
        if type_of_resource.present?
          @generic_file.resource_type = [type_of_resource.first]
        else
          raise "Could not find type of resource for #{@record_meta_xml.xpath(".//typeOfResource").text.strip}"
        end

        genre = Sufia.config.genre_list.keys.select { |item| item.downcase == @record_meta_xml.xpath(".//genre").text.strip.downcase }
        if genre.present?
          @generic_file.genre = genre
        else
          railse "Could not find genre for #{@record_meta_xml.xpath(".//genre").text.strip}"
        end

        @record_meta_xml.xpath(".//note").each do |description_element|
          @generic_file.description += [description_element.text.strip] if description_element.present? and !description_element.text.strip.include?('General note:')
          @generic_file.digital_format = description_element.text.gsub('General note:', '').strip if description_element.present? and description_element.text.strip.include?('General note:') and description_element.text.strip.include?('title')
        end

        @record_meta_xml.xpath('.//relatedItem[displayLabel="part of"]').each do |description_element|
          @generic_file.description += ['Part of ' + description_element.text.strip] if description_element.present?
        end

        @record_meta_xml.xpath(".//accessCondition").each do |access_condition|
          @generic_file.rights_free_text += [access_condition.text.strip] if access_condition.present?
        end
        @generic_file.rights = ["Contact host institution for more information"]


        time_in_utc = DateTime.now.new_offset(0)
        @generic_file.date_uploaded = time_in_utc
        @generic_file.date_modified = time_in_utc
        @generic_file.visibility = 'restricted'


        begin

          image_path = @record_meta_xml.xpath('.//url[@displayLabel="Full Image"]').text.strip
          image_path ||= @record_meta_xml.xpath('.//url[@displayLabel="Thumbnail"]').text.strip

          # The redirection ends in a ":" part without an extension that causes ImageMagick problems. So get
          # The redirection and then do the conversion
          image_path.gsub!(/http[s]*/, 'https')
          url = URI.parse(image_path)
          req = Net::HTTP::Get.new(url.path, { 'User-Agent' => 'Mozilla/5.0 (etc...)' })
          response = Net::HTTP.start(url.host, url.port, :use_ssl => url.scheme == 'https') { |http| http.request(req) }

          img = MiniMagick::Image.open("#{response['location']}.jpg") do |b|
            b.format "jpg"
            b.resize "500x600>"
          end
          img.resize "500x600>"
          img.format "jpg"

          @generic_file.add_file(StringIO.open(img.to_blob), path:  'content', mime_type: 'image/jpeg')

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
          current_error = "Either image is corrupt, derivatives broken, or relationships not being set right for #{show_location} \n"
          current_error += "Error message: #{error.message}\n"
          current_error += "Error backtrace: #{error.backtrace}\n"
          raise(current_error)
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