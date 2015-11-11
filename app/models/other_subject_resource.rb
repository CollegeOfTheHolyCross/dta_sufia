class OtherSubjectResource

  def self.find_location(subject)
    #solr_response = ActiveFedora::Base.find_with_conditions({subject_tesim: "test"} , rows: '10', fl: 'subject_tesim' )
    #ActiveFedora::Base.find_each("subject_tesim:tes*") { |x| puts 'hi' }

    solr_response = ActiveFedora::Base.find_with_conditions("subject_tesim:#{URI.escape(subject)}*", rows: '10', fl: 'subject_tesim' )

    if solr_response.present?
      values = []
      solr_response.each do |indv_response|
        indv_response["subject_tesim"].each do |indv_subj|
          values << indv_subj
        end
      end

      values = values.uniq.take(10)
      return values.map! { |item|
        count = ActiveFedora::Base.find_with_conditions("subject_tesim:#{URI.escape(item)}", rows: '100', fl: 'subject_tesim' ).length
        if count >= 99
          count = "99+"
        else
          count = count.to_s
        end

        {
          label: "#{item} (#{count})", value: item
        }
      }
    else
      return []
    end
  end
end
