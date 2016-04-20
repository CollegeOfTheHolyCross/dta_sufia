class Institution < ActiveFedora::Base
  include Hydra::WithDepositor # for access to apply_depositor_metadata
  include Hydra::AccessControls::Permissions
  include Sufia::Permissions::Readable
  include Sufia::Noid

  contains "content", class_name: 'FileContentDatastream'
  contains "thumbnail"

  has_many :members, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasCollectionMember, class_name: "Collection"

  has_many :files, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasMember, class_name: "GenericFile"

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

  def label
    return self.name
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

    #FIXME: THESE ACTUALLY AREN't public...
    #doc['is_public_ssi'] = self.public?.to_s
    doc['is_public_ssi'] = true.to_s

    doc['institution_name_ssim'] = []

    doc['title_primary_ssort'] = self.name.gsub(/^The /, '').gsub(/^A /, '').gsub(/^An /, '')

    doc['institution_name_ssim'] << self.name

    doc['has_image_ssi'] = self.content.present?.to_s

    doc
  end

end
