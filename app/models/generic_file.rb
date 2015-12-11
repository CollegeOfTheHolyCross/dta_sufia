class GenericFile < ActiveFedora::Base
  include Sufia::GenericFile
  
  property :analog_format, predicate: ::RDF::DC.format, multiple: false do |index|
    index.as :stored_searchable
  end
  
  property :digital_format, predicate: ::RDF::DC11.format, multiple: false do |index|
    index.as :stored_searchable
  end
  
  property :temporal_coverage, predicate: ::RDF::DC.temporal do |index|
    index.as :stored_searchable
  end
  
  property :date_issued, predicate: ::RDF::DC.issued do |index|
    index.as :stored_searchable
  end
  #::RDF::SCHEMA.
  property :genre, predicate: ::RDF::Vocab::EDM.hasType do |index|
    index.as :stored_searchable
  end
  
  property :alternative, predicate: ::RDF::DC.alternative do |index|
    index.as :stored_searchable
  end

  #http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#adultContent is boolean only :(
  #FIXME: Both rights and flagged have multiple set to true and their forms generate with that...
  #FIXME: MULTIPLE SHOULD BE FALSE!!! Main page gives an error though if it is... ><
  property :flagged, predicate: ::RDF::URI.new('http://digitaltransgenderarchive.net/ns/flagged'), multiple: false do |index|
    index.as :stored_searchable
  end

  property :lcsh_subject, predicate: ::RDF::DC.subject do |index|
    index.as :stored_searchable, :facetable, :symbol
  end

  property :other_subject, predicate: ::RDF::DC.subject do |index|
    index.as :stored_searchable, :facetable, :symbol
  end

  property :homosaurus_subject, predicate: ::RDF::DC.subject do |index|
    index.as :stored_searchable, :facetable, :symbol
  end

  def lcsh_subject_label
    ['hello']
  end

  def to_solr(doc = {} )
    doc = super(doc)

    doc['dta_homosaurus_subject_ssim'] = []
    doc['dta_lcsh_subject_ssim'] = []
    doc['dta_other_subject_ssim'] = []
    doc['dta_all_subject_ssim'] = []
    doc['dta_altLabel_all_subject_ssim'] = []

    self.subject.each do |subject|
      if subject.match(/http:\/\/homosaurus\.org\/terms\//)
        term = Homosaurus.find('homosaurus/terms/' + subject.split('/').last)
        doc['dta_homosaurus_subject_ssim'] << term.prefLabel
        doc['dta_all_subject_ssim'] << term.prefLabel
        term.altLabel.each do |alt|
          doc['dta_altLabel_all_subject_ssim'] << alt
        end

      elsif subject.match(/http:\/\/id.loc.gov\/authorities\/subjects\//)
        #FIXME: TODO
      else
        doc['dta_other_subject_ssim'] << subject
        doc['dta_all_subject_ssim'] << subject

      end
    end

    doc



  end
end