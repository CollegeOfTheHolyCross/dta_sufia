class HomosaurusV2 < ActiveFedora::Base

  has_and_belongs_to_many :broader, predicate: ::RDF::Vocab::SKOS.broader, class_name: "HomosaurusV2"
  has_and_belongs_to_many :narrower, predicate: ::RDF::Vocab::SKOS.narrower, class_name: "HomosaurusV2"
  has_and_belongs_to_many :related, predicate: ::RDF::Vocab::SKOS.related, class_name: "HomosaurusV2"

  property :identifier, predicate: ::RDF::Vocab::DC.identifier, multiple: false do |index|
    index.as :stored_sortable
  end

  property :prefLabel, predicate: ::RDF::Vocab::SKOS.prefLabel, multiple: false do |index|
    index.as :stored_searchable, :symbol
  end

  property :altLabel, predicate: ::RDF::Vocab::SKOS.altLabel, multiple: true do |index|
    index.as :stored_searchable, :symbol
  end

  property :description, predicate: ::RDF::RDFS.comment, multiple: false do |index|
    index.as :stored_searchable, :symbol
  end

  property :description, predicate: ::RDF::RDFS.comment, multiple: false do |index|
    index.as :stored_searchable, :symbol
  end

  property :issued, predicate: ::RDF::DC.issued, multiple: false do |index|
    index.as :stored_sortable
  end

  property :modified, predicate: ::RDF::DC.modified, multiple: false do |index|
    index.as :stored_sortable
  end

  property :exactMatch, predicate: ::RDF::Vocab::SKOS.exactMatch, multiple: true do |index|
    index.as :stored_searchable, :symbol
  end

  property :closeMatch, predicate: ::RDF::Vocab::SKOS.closeMatch, multiple: true do |index|
    index.as :stored_searchable, :symbol
  end

  def show_fields
    attributes.keys - ["id", "broader_ids", "narrower_ids", "related_ids"]
  end

  def terms
    #fields - [:issued, :modified]
    attributes.keys - ["issued", "modified", "identifier", "id", "broader_ids", "narrower_ids", "related_ids"]
  end

  def required? key
    return true if ['prefLabel', 'identifier'].include? key
    return false
  end

=begin
  def self.multiple? field
    #FIXME
    return false if ['preferred_label', 'description'].include? field.to_s
    return true
  end
=end

  def to_solr(doc = {} )
    doc = super(doc)

    doc['dta_homosaurus_lcase_prefLabel_ssi'] = self.prefLabel.downcase
    doc['dta_homosaurus_lcase_altLabel_ssim'] = []
    doc['topConcept_ssim'] = []
    self.altLabel.each do |alt|
      doc['dta_homosaurus_lcase_altLabel_ssim'] << alt
    end

    doc['dta_homosaurus_lcase_comment_tesi'] = self.description

    @broadest_terms = []
    get_broadest(self)
    doc['topConcept_ssim'] = @broadest_terms if @broadest_terms.present?
    doc

  end

  def get_broadest(item)
    if item.broader.blank?
      @broadest_terms << item.id.split('/').last
    else
      item.broader.each do |current_broader|
        get_broadest(current_broader)
      end
    end
  end

end