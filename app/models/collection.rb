class Collection < Sufia::Collection
  has_and_belongs_to_many :institutions, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isMemberOfCollection, class_name: "Institution"

  #has_many :institutions, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isMemberOfCollection, class_name: "Institution"

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

  property :thumbnail_ident, predicate: ::RDF::URI.new("http://digitaltransgenderarchive.net/ns/collectionThumbnail"), multiple: false do |index|
  end

  def update_permissions
    self.visibility = "open" unless self.visibility == 'restricted'
  end

  def to_solr(doc = {} )
    doc = super(doc)

    doc['thumbnail_ident_ss'] = self.thumbnail_ident if self.thumbnail_ident.present?

    doc['is_public_ssi'] = self.public?.to_s

    doc['title_primary_ssort'] = self.title.gsub(/^The /, '').gsub(/^A /, '').gsub(/^An /, '')
    doc['title_primary_ssi'] = self.title

    doc['institution_name_ssim'] = []
    self.institutions.each do |institution|
      doc['institution_name_ssim'] << institution.name
      doc['institution_pid_ssi'] = institution.id
    end

    doc['institution_name_ssim'].uniq! #unsure why this is needed... figure out later

    doc['collection_name_ssim'] = self.title




    doc
  end

end
