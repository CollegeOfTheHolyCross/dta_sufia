require 'zip'

module InternetArchive
  class DtaBooks
    @queue = :internet_archive

    def self.perform(*args)
      args = args.first
      collection_id = 'digitaltransgenderarchive'
      @upload_collection_id = args["collection_id"]
      @upload_institution_id = args["institution_id"]
      @collection = ActiveFedora::Base.find(@upload_collection_id)
      @institution = ActiveFedora::Base.find(@upload_institution_id)
      @depositor = args["depositor"]
      #@url = "http://archive.org/advancedsearch.php?q=collection%3A%22#{collection_id}%22&fl%5B%5D=identifier&output=json&rows=10000"
      @url = "http://archive.org/advancedsearch.php?q=collection%3A%22#{collection_id}%22&fl%5B%5D=identifier&output=json&rows=3"

      record_metasource_xml = nil
      list_response = Typhoeus::Request.get(@url)
      list_response_as_json = JSON.parse(list_response.body)
      list_response_as_json["response"]["docs"].each do |result|
        ia_id = result['identifier']
        @ia_id = ia_id

        solr_response = GenericFile.find_with_conditions("identifier_tesim:#{ia_id}", rows: '25', fl: 'id' )
        if solr_response.blank?

          record_metasource = Typhoeus::Request.get("http://archive.org/download/#{result['identifier']}/#{result['identifier']}_metasource.xml", {:followlocation => true})
          record_metasource_xml= Nokogiri::XML(record_metasource.body)

          record_meta = Typhoeus::Request.get("http://archive.org/download/#{result['identifier']}/#{result['identifier']}_meta.xml", {:followlocation => true})
          @record_meta_xml= Nokogiri::XML(record_meta.body)

          scan_data_response = Typhoeus::Request.get("http://archive.org/download/#{ia_id}/#{ia_id}_scandata.xml", {:followlocation => true})
          scan_data_xml = Nokogiri::XML(scan_data_response.body)


          djvu_data_text_response = Typhoeus::Request.get("http://archive.org/download/#{ia_id}/#{ia_id}_djvu.txt", {:followlocation => true})
          djvu_data_text = djvu_data_text_response.body


          @generic_file = ::GenericFile.new
          @generic_file.depositor = @depositor
          @generic_file.permissions_attributes = [{ type: 'group', name: 'public', access: 'read' }, {type: 'group', name: 'admin', access: 'edit'}, {type: 'group', name: 'superuser', access: 'edit'}]
          @generic_file.edit_users += [@depositor]

          volume = @record_meta_xml.xpath("//volume").first.text if @record_meta_xml.xpath("//volume").present?
          main_title = nil
          alternative_titles = []
          @record_meta_xml.xpath("//title").each do |title_element|
            if main_title.blank?
              main_title = title_element.text
            else
              alternative_titles << title_element.text
            end
          end

          main_title = "#{main_title} (#{volume})"

          @generic_file.title = [main_title]
          @generic_file.alternative = alternative_titles if alternative_titles.present?
          @generic_file.label = main_title
          @generic_file.identifier = [ia_id]
          #@generic_file.ocr = djvu_data_text.to_s.force_encoding("UTF-8")
          @generic_file.hosted_elsewhere = "1"
          @generic_file.is_shown_at = "https://archive.org/details/#{ia_id}"

          @record_meta_xml.xpath("//subject").each do |subject_element|
            solr_response = Homosaurus.find_with_conditions("dta_homosaurus_lcase_prefLabel_ssi:#{solr_clean(subject_element.text.downcase)}", rows: '25', fl: 'identifier_ssi, prefLabel_ssim, altLabel_ssim, narrower_ssim, broader_ssim, related_ssim' )
            if solr_response.present? and solr_response.count == 1
              @generic_file.homosaurus_subject += ['http://homosaurus.org/terms/' + solr_response.first['identifier_ssi']]
            elsif  solr_response.present? and solr_response.count > 1
              raise "Solr count mismatch"
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

          @record_meta_xml.xpath("//publisher").each do |publisher_element|
            @generic_file.publisher += [publisher_element.text] if publisher_element.present?
          end

          @record_meta_xml.xpath("//creator").each do |creator_element|
            @generic_file.creator += [creator_element.text] if creator_element.present?
          end

          @record_meta_xml.xpath("//description").each do |description_element|
            @generic_file.description += [description_element.text] if description_element.present?
          end

          @generic_file.rights = ["No known restrictions on use"]

          time_in_utc = DateTime.now.new_offset(0)
          @generic_file.date_uploaded = time_in_utc
          @generic_file.date_modified = time_in_utc
          @generic_file.visibility = 'restricted'


          zip_file_path = "http://archive.org/download/#{ia_id}/#{ia_id}_jp2.zip"
          zipfile = Tempfile.new(['iazip','.zip'])
          zipfile.binmode # This might not be necessary depending on the zip file
          zipfile.write(Typhoeus.get(zip_file_path, followlocation: true).body)
          zipfile.close

          cover_image = nil
          leafNum = nil
          scan_data_xml.xpath("//pageData/page").each do |page|
            page_type = page.xpath('./pageType').first.text
            if page_type == 'Cover'
              leafNum ||= page.attributes["leafNum"].text
              cover_image ||= ia_id + '_' + "0000"[0..3-leafNum.length] + leafNum + ".jp2"
            end
          end



          ::Zip::File.open(zipfile.path) do |file|

            file_path = "#{@ia_id}_jp2/#{cover_image}"
            entry = file.get_entry(file_path)
            iajp2file = Tempfile.new(['iajp2file','.jp2'])
            iajp2file.write(entry.get_input_stream.read)
            iajp2file.close

            img = Magick::Image.read(iajp2file.path).first
            img = Magick::Image.from_blob( img.to_blob { self.format = "jpg" } ).first


            thumb = img.resize_to_fit(500,600) #FIXME?
            @generic_file.add_file(StringIO.open(thumb.to_blob), path:  'content', mime_type: 'image/jpeg')


            @generic_file.save

            @collection.add_members [@generic_file.id]
            @generic_file.collections = @generic_file.collections + [@collection]
            @collection.save

            @institution.files = @institution.files + [@generic_file]
            @generic_file.institutions = @generic_file.institutions + [@institution]
            @institution.save
            @generic_file.save

            Sufia.queue.push(CharacterizeJob.new(@generic_file.id))

            iajp2file.delete
          end
          zipfile.delete

        end
      end
    end

    def self.solr_clean(term)
      return term.gsub('\\', '\\\\').gsub(':', '\\:').gsub(' ', '\ ')
    end

  end
end