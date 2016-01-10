class Collection < Sufia::Collection
  has_and_belongs_to_many :institutions, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isMemberOfCollection, class_name: "Institution"

=begin
  property :institutions, predicate: ::RDF::URI.new("http://dbpedia.org/ontology/institution"), multiple: false do |index|
      index.as :stored_searchable, :facetable
  end
=end

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

  def to_solr(doc = {} )
    doc = super(doc)
    doc['institution_name_ssim'] = []
    self.institutions.each do |institution|
      doc['institution_name_ssim'] << institution.name
    end

    doc['collection_name_ssim'] = self.title


    doc
  end

end
