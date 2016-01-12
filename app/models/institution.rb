class Institution < ActiveFedora::Base
  include Hydra::WithDepositor # for access to apply_depositor_metadata
  include Hydra::AccessControls::Permissions

  has_many :members, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasCollectionMember, class_name: "Collection"

  property :date_created, predicate: ::RDF::Vocab::DC.created, multiple: false do |index|
    index.type :text
    index.as :stored_searchable, :symbol, :facetable
  end

  property :name, predicate: ::RDF::Vocab::SKOS.prefLabel, multiple: false do |index|
    index.type :text
    index.as :stored_searchable, :symbol, :facetable
  end

  property :description, predicate: ::RDF::RDFS.comment, multiple: false do |index|
    index.as :stored_searchable, :symbol
  end

  property :contact_person, predicate: ::RDF::URI.new("http://digitaltransgenderarchive.net/ns/contactPerson"), multiple: false do |index|
    index.type :text
    index.as :stored_searchable, :symbol
  end

  property :address, predicate: ::RDF::Vocab::SCHEMA.address, multiple: false do |index|
    index.type :text
    index.as :stored_searchable, :symbol
  end

  property :email, predicate: ::RDF::Vocab::SCHEMA.email, multiple: false do |index|
    index.type :text
    index.as :stored_searchable, :symbol
  end

  property :phone, predicate: ::RDF::Vocab::SCHEMA.telephone, multiple: false do |index|
    index.type :text
    index.as :stored_searchable, :symbol
  end
  
  property :institution_url, predicate: ::RDF::RDFS.seeAlso, multiple: false do |index|
    index.as :stored_searchable
  end

  def show_fields
    attributes.keys - ["id", "members_ids"]
  end

  def terms
    #fields - [:issued, :modified]
    attributes.keys - ["date_created", "id", "members_ids"]
  end

  def required? key
    return true if ['name', 'institution_url'].include? key
    return false
  end

  def to_solr(doc = {} )
    doc = super(doc)
    doc['institution_name_ssim'] = []

    doc['title_primary_ssort'] = self.name
    doc['institution_name_ssim'] << self.name


    doc
  end

end
