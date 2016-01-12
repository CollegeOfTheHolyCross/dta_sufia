module DtaSearchBuilder

  def exclude_unwanted_models(solr_parameters = {}, wtf=nil)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "-active_fedora_model_ssi:\"Institution\""
    solr_parameters[:fq] << "-active_fedora_model_ssi:\"Collection\""
    # can't implement below until all records have this field
    # solr_parameters[:fq] << '+workflow_state_ssi:"published"'
    # solr_parameters[:fq] << '+processing_state_ssi:"complete"'
  end

# used by InstitutionsController#index
def institutions_filter(solr_parameters = {}, wtf=nil)
  solr_parameters[:fq] ||= []
  solr_parameters[:fq] << "+active_fedora_model_ssi:\"Institution\""
end

# used by CollectionsController#public_index
def collections_filter(solr_parameters = {}, wtf=nil)
  solr_parameters[:fq] ||= []
  solr_parameters[:fq] << "+active_fedora_model_ssi:\"Collection\""
end
end