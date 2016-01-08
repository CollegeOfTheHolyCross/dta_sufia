module DtaSearchBuilder
# used by InstitutionsController#index
def institutions_filter(solr_parameters = {})
  solr_parameters[:fq] ||= []
  solr_parameters[:fq] << "+active_fedora_model_suffix_ssi:\"Institution\""
end

# used by CollectionsController#public_index
def collections_filter(solr_parameters = {}, wtf=nil)
  solr_parameters[:fq] ||= []
  solr_parameters[:fq] << "+active_fedora_model_suffix_ssi:\"Collection\""
end
end