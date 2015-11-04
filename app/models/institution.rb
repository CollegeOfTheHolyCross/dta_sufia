class Institution < Sufia::Collection

  property :contact_person, predicate: ::RDF::URI.new("http://digitaltransgenderarchive.net/ns/contactPerson"), multiple: false do |index|
    index.type :text
    index.as :stored_searchable
  end

  property :address, predicate: ::RDF::SCHEMA.address, multiple: false do |index|
    index.type :text
    index.as :stored_searchable
  end
  
  property :institution_url, predicate: ::RDF::RDFS.seeAlso, multiple: false do |index|
    index.as :stored_searchable
  end

end
