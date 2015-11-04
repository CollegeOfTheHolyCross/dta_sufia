module Hydra::Collections::SelectsCollections
  extend ActiveSupport::Concern

  included do
    configure_blacklight do |config|
      config.search_builder_class = Hydra::Collections::SearchBuilder
    end
  end

  def access_levels
    { read: [:read, :edit], edit: [:edit] }
  end

  ##
  # Return list of collections for which the current user has read access.
  # Add this or find_collections_with_edit_access as a before filter on any page that shows the form_for_select_collection
  #
  # @return [Array<SolrDocument>] Solr documents for each collection the user has read access
  def find_collections_with_read_access
    find_collections(:read)
  end

  ##
  # Return list of collections for which the current user has edit access.  Optionally prepend with default
  # that can be used in a select menu to instruct user to select a collection.
  # Add this or find_collections_with_read_access as a before filter on any page that shows the form_for_select_collection
  #
  # @param [TrueClass|FalseClass] :include_default if true, prepends the default_option; otherwise, if false, returns only collections
  # @param [Fixnum] :default_id for select menus, this is the id of the first selection representing the instructions
  # @param [String] :default_title for select menus, this is the text displayed as the first item serving as instructions
  #
  # @return [Array<SolrDocument>] Solr documents for each collection the user has edit access, plus optional instructions
  def find_collections_with_edit_access(include_default=false, default_id=-1, default_title="Select collection...")
    find_collections(:edit)
    default_option = SolrDocument.new(id: default_id, title_tesim: default_title)
    @user_collections.unshift(default_option) if include_default
  end

  ##
  # Return list of collections matching the passed in access_level for the current user.
  # @param [Symbol] :access_level one of :read or :edit
  # @return [Array<SolrDocument>] Solr documents for each collection the user has the appropriate access level
  def find_collections (access_level = nil)
    # need to know the user if there is an access level applied otherwise we are just doing public collections
    authenticate_user! unless access_level.blank?

    # run the solr query to find the collections
    query = collections_search_builder(access_level).with({q: ''}).query
    response = repository.search(query)

    # return the user's collections (or public collections if no access_level is applied)
    @user_collections = response.documents
  end

  def collections_search_builder_class
    Hydra::Collections::SearchBuilder
  end

  def collections_search_builder(access_level = nil)
    @collections_search_builder ||= collections_search_builder_class.new(collection_search_params_logic, self).tap do |builder|
      builder.current_ability = current_ability
      builder.discovery_perms = access_levels[access_level] if access_level && !current_user.contributor? && !current_user.admin? && !current_user.superuser?
    end
  end

  # Defines which search_params_logic should be used when searching for Collections
  def collection_search_params_logic
    [:default_solr_parameters, :add_query_to_solr, :add_access_controls_to_solr_params,
     :add_collection_filter, :some_rows]
  end

end
