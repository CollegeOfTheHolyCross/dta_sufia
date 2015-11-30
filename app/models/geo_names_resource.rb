class GeoNamesResource
  def self.find_location(subject)
    authority_check = Mei::Geonames.new
    authority_result = authority_check.search(subject) #URI escaping doesn't work for Baseball fields?
    if authority_result.present?
      return authority_result
    else
      return []
    end
  end

end