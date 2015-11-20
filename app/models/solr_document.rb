# -*- encoding : utf-8 -*-
class SolrDocument 

  ##EDIT##
  #include Blacklight::Solr::Document
  include Blacklight::Document
  #require_relative 'document/more_like_this'

  include Blacklight::Document::ActiveModelShim
  include Blacklight::Solr::Document::MoreLikeThis
  ##EDIT##

  include Blacklight::Gallery::OpenseadragonSolrDocument

  # Adds Sufia behaviors to the SolrDocument.
  include Sufia::SolrDocumentBehavior


  # self.unique_key = 'id'
  
  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension( Blacklight::Document::Email )
  
  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension( Blacklight::Document::Sms )

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension( Blacklight::Document::DublinCore)    


  # Do content negotiation for AF models. 

  use_extension( Hydra::ContentNegotiation )

  def create_date
    Array(self[Solrizer.solr_name('date_created')]).first
  end

  def institution
    Array(self[Solrizer.solr_name('institution')]).first
  end

  ##EDIT##
  def has_highlight_field? k
    return false if response['highlighting'].blank? or response['highlighting'][self.id].blank?

    response['highlighting'][self.id].key? k.to_s
  end

  def highlight_field k
    response['highlighting'][self.id][k.to_s].map(&:html_safe) if has_highlight_field? k
  end
  ##EDIT##
end
