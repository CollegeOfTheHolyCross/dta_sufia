class LcshSubjectResource

  def self.find_location(subject)
    authority_check = Qa::Authorities::Loc.subauthority_for('subjects')
    authority_result = authority_check.search(subject) #URI escaping doesn't work for Baseball fields?
    if authority_result.present?
      return authority_result.map! { |item| { label: item["label"], value: item["id"].gsub('info:lc', 'http://id.loc.gov') } }
    else
      return []
    end
  end
end
