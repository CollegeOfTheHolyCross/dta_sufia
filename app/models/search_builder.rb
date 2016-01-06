class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include Hydra::AccessControlsEnforcement
  include Sufia::SearchBuilder

=begin
  def current_ability
    if current_user.present?
      ddfdfd
      Ability.new(current_user)
    else
      Ability.new(nil)
    end

    #Ability.new(nil)
  end
=end

  def show_only_collections(solr_parameters)
    if !current_user.superuser?
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] += [
          ActiveFedora::SolrQueryBuilder.construct_query_for_rel(has_model: Collection.to_class_uri)
      ]
    end

  end

  def show_only_resources_deposited_by_current_user(solr_parameters)
    if !current_user.superuser?
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] += [
          ActiveFedora::SolrQueryBuilder.construct_query_for_rel(depositor: scope.current_user.user_key)
      ]
    end
  end
end
