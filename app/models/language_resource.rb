class LanguageResource

  def self.find_location(language)
    authority_check = Qa::Authorities::Loc.subauthority_for('iso639-2')
    authority_result = authority_check.search(URI.escape(language)+'*')
    if authority_result.present?
      return authority_result.map! { |item| { label: item["label"], value: item["id"].gsub('info:lc', 'http://id.loc.gov') } }
    else
      return []
    end
  end
end
