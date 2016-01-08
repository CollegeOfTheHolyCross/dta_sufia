module Hydra::AccessControlsEnforcement
  extend ActiveSupport::Concern

  included do |klass|
    attr_writer :current_ability
    class_attribute :solr_access_filters_logic

    # Set defaults. Each symbol identifies a _method_ that must be in
    # this class, taking one parameter (permission_types)
    # Can be changed in local apps or by plugins, eg:
    # CatalogController.include ModuleDefiningNewMethod
    # CatalogController.solr_access_filters_logic += [:new_method]
    # CatalogController.solr_access_filters_logic.delete(:we_dont_want)
    self.solr_access_filters_logic = [:apply_group_permissions, :apply_user_permissions]

  end

  #STEVEN: MODIFIED for Date range limit. Is this fine? Seems to also break the ranges yet...
  def current_ability
    @current_ability || ::Ability.new(nil)
        #raise("current_ability has not been set on #{self}")
  end

  protected

  def gated_discovery_filters(permission_types = discovery_permissions, ability = current_ability)
    user_access_filters = []

    # Grant access based on user id & group

    #FIXME: STEVEN - temporary hack?
    if permission_types.present?
      solr_access_filters_logic.each do |method_name|
        user_access_filters += send(method_name, permission_types, ability)
      end
    end

    user_access_filters
  end

  def under_embargo?
    load_permissions_from_solr
    embargo_key = Hydra.config.permissions.embargo.release_date
    if @permissions_solr_document[embargo_key]
      embargo_date = Date.parse(@permissions_solr_document[embargo_key].split(/T/)[0])
      return embargo_date > Date.parse(Time.now.to_s)
    end
    false
  end

  #
  # Action-specific enforcement
  #

  # Controller "before" filter for enforcing access controls on show actions
  # @param [Hash] opts (optional, not currently used)
  def enforce_show_permissions(opts={})
    permissions = current_ability.permissions_doc(params[:id])
    if permissions.under_embargo? && !can?(:edit, permissions)
      raise Hydra::AccessDenied.new("This item is under embargo.  You do not have sufficient access privileges to read this document.", :edit, params[:id])
    end
    unless can? :read, permissions
      raise Hydra::AccessDenied.new("You do not have sufficient access privileges to read this document, which has been marked private.", :read, params[:id])
    end
  end

  # Solr query modifications
  #

  # Set solr_parameters to enforce appropriate permissions
  # * Applies a lucene query to the solr :q parameter for gated discovery
  # * Uses public_qt search handler if user does not have "read" permissions
  # @param solr_parameters the current solr parameters
  #
  # @example This method should be added to your CatalogController's search_params_logic
  #   class CatalogController < ApplicationController
  #     CatalogController.search_params_logic += [:add_access_controls_to_solr_params]
  #   end
  def add_access_controls_to_solr_params(solr_parameters)
    apply_gated_discovery(solr_parameters)
  end


  # Which permission levels (logical OR) will grant you the ability to discover documents in a search.

  # Override this method if you want it to be something other than the default
  def discovery_permissions
    @discovery_permissions ||= ["edit","discover","read"]
  end
  def discovery_permissions= (permissions)
    @discovery_permissions = permissions
  end

  # Contrller before filter that sets up access-controlled lucene query in order to provide gated discovery behavior
  # @param solr_parameters the current solr parameters
  def apply_gated_discovery(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << gated_discovery_filters.join(" OR ")
    Rails.logger.debug("Solr parameters: #{ solr_parameters.inspect }")
  end


  def apply_group_permissions(permission_types, ability = current_ability)
    # for groups
    user_access_filters = []
    ability.user_groups.each_with_index do |group, i|
      permission_types.each do |type|
        user_access_filters << escape_filter(Hydra.config.permissions[type.to_sym].group, group)
      end
    end
    user_access_filters
  end

  def escape_filter(key, value)
    [key, value.gsub(/[ :\/]/, ' ' => '\ ', '/' => '\/', ':' => '\:')].join(':')
  end

  def apply_user_permissions(permission_types, ability = current_ability)
    # for individual user access
    user_access_filters = []
    user = ability.current_user
    if user && user.user_key.present?
      permission_types.each do |type|
        user_access_filters << escape_filter(Hydra.config.permissions[type.to_sym].individual, user.user_key)
      end
    end
    user_access_filters
  end
end