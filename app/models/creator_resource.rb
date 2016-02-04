class CreatorResource

  def self.find_location(subject)
    #solr_response = ActiveFedora::Base.find_with_conditions({subject_tesim: "test"} , rows: '10', fl: 'subject_tesim' )
    #ActiveFedora::Base.find_each("subject_tesim:tes*") { |x| puts 'hi' }


    solr_response = ActiveFedora::Base.find_with_conditions("creator_ssim:#{solr_wildcard_clean(subject)}*", rows: '50', fl: 'creator_ssim' )

    #FIXME - A result for "http" gives back the entire array of values...
    if solr_response.present?
      values = []
      solr_response.each do |indv_response|
        indv_response["creator_ssim"].each do |indv_subj|
          if indv_subj.match(/#{subject}/)
            values << indv_subj
          end
        end
      end

      values = values.uniq.take(10)

      return values.map! { |item|
        ##{URI.escape(item)}
        count = ActiveFedora::Base.find_with_conditions("creator_ssim:#{solr_exact_clean(item)}", rows: '100', fl: 'creator_ssim' ).length
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

  def self.solr_wildcard_clean(term)
    return term.gsub('\\', '\\\\').gsub(':', '\\:').gsub(' ', '\ ')
  end

  def self.solr_exact_clean(term)
    #FIXME: This stinks and is a bad workaround. Will fail if both paranthesis and quotes.
    if term.include?(')') || term.include?('(')
      return "\"#{term}\""
    else
      return "(#{term})"
    end

  end
end

