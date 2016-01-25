class OtherSubjectResource

  def self.find_location(subject)
    #solr_response = ActiveFedora::Base.find_with_conditions({subject_tesim: "test"} , rows: '10', fl: 'subject_tesim' )
    #ActiveFedora::Base.find_each("subject_tesim:tes*") { |x| puts 'hi' }

    exclude_lcsh = 'http://id.loc.gov/authorities/subjects/'
    exclude_homosaurus= 'http://homosaurus.org/terms/'
    solr_response = ActiveFedora::Base.find_with_conditions("other_subject_ssim:#{solr_wildcard_clean(subject)}*", rows: '50', fl: 'other_subject_ssim' )

    #FIXME - A result for "http" gives back the entire array of values...
    if solr_response.present?
      values = []
      solr_response.each do |indv_response|
        indv_response["other_subject_ssim"].each do |indv_subj|
          if indv_subj.match(/#{subject}/) && !indv_subj.match(/http:\/\/id\.loc\.gov\/authorities\/subjects\//) && !indv_subj.match(/http:\/\/homosaurus\.org\/terms\//)
            values << indv_subj
          end
        end
      end

      values = values.uniq.take(10)

      return values.map! { |item|
        ##{URI.escape(item)}
        count = ActiveFedora::Base.find_with_conditions("other_subject_ssim:#{solr_exact_clean(item)}", rows: '100', fl: 'other_subject_ssim' ).length
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
