# encoding: utf-8

module SanAntonio
  class SingleObject < IngestBase
    @queue = :internet_archive

    #  lopez and cardona - Victor Lopez and Rudy Cardona Photograph Collection, MS 476
    #   source: box 1, folder 1
    # IsPartOf: Hattie Elam Briscoe Papers, University of Texas at San Antonio Libraries, MS 67, Box 1, Folder 1, Scan 2

    def self.perform(*args)
      args = args.first

      @antonio_id = args["record_id"]
      @upload_collection_id = args["collection_id"]
      @upload_institution_id = args["institution_id"]

      @depositor = args["depositor"]
      @record_meta_xml = Nokogiri::XML(args["metadata"])
      @record_meta_xml.remove_namespaces!
      retry_count = 0

      text_check = []

      text_check << @record_meta_xml.xpath(".//source").text.strip.downcase
      text_check << @record_meta_xml.xpath(".//relation").text.strip.downcase
      text_check << @record_meta_xml.xpath(".//description").text.strip.downcase
      text_check << @record_meta_xml.xpath(".//title").text.strip.downcase
      text_check << @record_meta_xml.xpath(".//subject").text.strip.downcase
      extra_check_text = text_check.join(" ")
      if (extra_check_text.include?('box 1') || extra_check_text.include?('folder 1')) && extra_check_text.include?('lopez') && extra_check_text.include?('cardona')


      @collection = ActiveFedora::Base.find(@upload_collection_id)
      @institution = ActiveFedora::Base.find(@upload_institution_id)

      show_location = ''
      @record_meta_xml.xpath(".//identifier").each do |identifier_element|
        show_location = identifier_element.text.strip if identifier_element.text.include? 'http'
      end
      raise 'could not find a show location' if show_location.blank?

      full_escaped_uri = solr_clean(show_location)
      solr_response = GenericFile.find_with_conditions("identifier_ssim:#{full_escaped_uri}", rows: '25', fl: 'id' )
      if solr_response.present?
        raise "Duplicate for #{show_location}. This id is #{solr_response.first["id"]}. The OAI ID is: #{@antonio_id}}"
      elsif solr_response.blank?

        @generic_file = ::GenericFile.new
        @generic_file.depositor = @depositor
        @generic_file.permissions_attributes = [{ type: 'group', name: 'public', access: 'read' }, {type: 'group', name: 'admin', access: 'edit'}, {type: 'group', name: 'superuser', access: 'edit'}]
        @generic_file.edit_users += [@depositor]

        main_title = nil
        alternative_titles = []
        @record_meta_xml.xpath(".//title").each do |title_element|
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
        @generic_file.hosted_elsewhere = "1"
        @generic_file.is_shown_at = show_location

        @record_meta_xml.xpath(".//description").each do |description_element|
          @generic_file.description += [description_element.text.strip] if description_element.present?
        end

        @record_meta_xml.xpath('.//relation').each do |description_element|
          @generic_file.description += ['Part of ' + description_element.text.strip] if description_element.present? and description_element.text.downcase.include? 'collection'
        end

        self.insert_date(@record_meta_xml.xpath('.//date').text) if @record_meta_xml.xpath('.//date').text.present? and @record_meta_xml.xpath('.//date').text.strip.downcase != "undated"

        #@generic_file.resource_type << @record_meta_xml.xpath(".//typeOfResource").text.strip

        @record_meta_xml.xpath(".//subject").each do |subject_with_semicolons|
          unless subject_with_semicolons.text == 'Lesbian, Gay, Bisexual, Transgender Resources'
          subject_with_semicolons.text.split(';').each do |subject_element|
            subject_element = subject_element.strip
            subject_element = subject_element[0..-2] if subject_element.match(/.+\.$/)
            self.insert_subject(subject_element, @antonio_id)
          end
          end
        end

        @record_meta_xml.xpath(".//publisher").each do |publisher|
          @generic_file.publisher += [publisher.text.strip] if publisher.present?
        end

        @record_meta_xml.xpath(".//relation").each do |relation|
          @generic_file.related_url += [relation.text.strip] if relation.present? and relation.text.include? 'http'
        end

        @record_meta_xml.xpath(".//rights").each do |access_condition|
          if access_condition.present?
            access_condition = 'Visit ' + "<a href=\"#{access_condition.text.strip}\" target=\"blank\">#{access_condition.text.strip}</a>" + ' for more information on this institution\'s copyright'
            @generic_file.rights_free_text += [access_condition]
          end
        end
        @generic_file.rights = ["Contact host institution for more information"]


        @generic_file.language += ['http://id.loc.gov/vocabulary/iso639-2/eng']
        @generic_file.genre += ['Photographs']
        @generic_file.resource_type += ['Still Image']

        time_in_utc = DateTime.now.new_offset(0)
        @generic_file.date_uploaded = time_in_utc
        @generic_file.date_modified = time_in_utc
        @generic_file.visibility = 'restricted'


        begin
          image_urls = []
          @base_url = "http://digital.utsa.edu/"
          collection_part = @antonio_id.split(':').last.split('/')[0]
          id_part = @antonio_id.split(':').last.split('/')[1]
          info_url = "http://digital.utsa.edu/utils/ajaxhelper/?CISOROOT=#{collection_part}&CISOPTR=#{id_part}"

          # http://digital.utsa.edu/cdm/ref/collection/p16018coll5/id/0
          # http://digital.utsa.edu/utils/ajaxhelper/?CISOROOT=p15125coll9&CISOPTR=41088
          # http://digital.utsa.edu/utils/ajaxhelper/?CISOROOT=p16018coll5&CISOPTR=0

          object_info = JSON.parse(RestClient.get info_url)

          if AUDIO_TYPES.include?(object_info['imageinfo']['type'])

            image_urls << "#{@base_url}utils/getthumbnail/collection/#{collection_part}/id/#{id_part}/filename/thumbnail.jpg"
          elsif object_info['imageinfo']['type'] == 'pdf' || object_info['imageinfo']['type'] == 'cpd'
            image_urls << "#{@base_url}utils/getfile/collection/#{collection_part}/id/#{id_part}/filename/pdf_file.pdf"
          else
            image_width = object_info['imageinfo']['width']
            image_height = object_info['imageinfo']['height']

            image_urls << "#{@base_url}utils/getprintimage/collection/#{collection_part}/id/#{id_part}/scale/100/width/#{image_width}/height/#{image_height}/rotate/0/filename/image_file.jpg"
          end

          img = MiniMagick::Image.open(image_urls[0]) do |b|
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

end
  end
end