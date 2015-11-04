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
  
  property :summary, predicate: ::RDF::DC.description, multiple: false do |index|
    index.as :stored_searchable
  end

  property :flagged, predicate: ::RDF::URI.new('http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#adultContent'), multiple: false do |index|
    index.as :stored_searchable
  end
  
end