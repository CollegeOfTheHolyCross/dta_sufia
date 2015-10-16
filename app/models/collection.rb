class Collection < Sufia::Collection
  property :institution, predicate: ::RDF::URI.new("http://dbpedia.org/ontology/institution") do |index|
      index.as :stored_searchable, :facetable
  end

  property :contact_person, predicate: ::RDF::URI.new("http://digitaltransgenderarchive.net/ns/contactPerson") do |index|
    index.type :text
    index.as :stored_searchable
  end

  property :address, predicate: ::RDF::SCHEMA.address, multiple: false do |index|
    index.type :text
    index.as :stored_searchable
  end

end
