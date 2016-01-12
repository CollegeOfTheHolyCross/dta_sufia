class CollectionsController < CatalogController
  include Sufia::CollectionsControllerBehavior
  include DtaSearchBuilder

  copy_blacklight_config_from(CatalogController)


  before_action :filter_docs_with_read_access!, except: :show
  before_action :has_access?, except: [:show, :public_index, :public_show]
  before_action :build_breadcrumbs, only: [:edit, :show, :public_show]
  before_filter :authenticate_user!, :except => [:show, :public_index, :public_show]


  before_filter :relation_base_blacklight_config, :only => [:show, :public_show]

  before_action :verify_admin, except: [:show, :public_index, :public_show] #FIXME on change member



  def index
    super
  end

  def show
    super
  end

  def public_show
    @nav_li_active = 'explore'
    @show_response, @document = fetch(params[:id])
    @collection_title = @document["title_tesim"].first

    # add params[:f] for proper facet links
    params[:f] = set_collection_facet_params(@collection_title, @document)

    # get the response for the facets representing items in collection
    (@response, @document_list) = search_results({:f => params[:f]}, search_params_logic)

    flash[:notice] = nil if flash[:notice] == "Select something first"

    respond_to do |format|
      format.html
    end
  end

  # set the correct facet params for facets from the collection
  def set_collection_facet_params(collection_title, document)
    facet_params = {blacklight_config.collection_field => [collection_title]}
    facet_params[blacklight_config.institution_field] = document[blacklight_config.institution_field.to_sym]
    facet_params
  end

  # Blacklight uses #search_action_url to figure out the right URL for
  # the global search box
  def search_action_url options = {}
    catalog_index_url(options.except(:controller, :action))
  end
  helper_method :search_action_url

  def public_index
=begin
    @nav_li_active = 'explore'

    query = collections_search_builder.with(params).query
    @response = repository.search(query)
    @document_list = @response.documents
    params[:view] = 'list'
    params[:sort] = 'title_primary_ssort asc'
=end

    @nav_li_active = 'explore'
    self.search_params_logic += [:collections_filter]
    (@response, @document_list) = search_results(params, search_params_logic)
    params[:view] = 'list'
    params[:sort] = 'title_info_primary_ssort asc'
    params[:per_page] = params[:per_page].presence || '50'

    flash[:notice] = nil if flash[:notice] == "Select something first"

    respond_to do |format|
      format.html
    end
  end

  def new
    institution_query = Institution.find_with_conditions("*:*", rows: '100000', fl: 'id,name_ssim' )
    @all_institutions = []
    institution_query.each { |term| @all_institutions << [term["name_ssim"].first, term["id"]] }
    flash[:notice] = nil if flash[:notice] == "Select something first"
    super
  end

  def edit
    institution_query = Institution.find_with_conditions("*:*", rows: '100000', fl: 'id,name_ssim' )
    @all_institutions = []
    institution_query.each { |term| @all_institutions << [term["name_ssim"].first, term["id"]] }
    super
  end

  def update
    #Update is called from other areas like moving an item to a collection... need to fix that...
    if params[:collection][:institution_ids].present?
      @collection.institutions.each do |institution|
        institution.members.delete(@collection)
        institution.save
      end
      @collection.reload
      @collection.institutions = []

      params[:collection][:institution_ids].each do |institution_id|
        institution = Institution.find(institution_id)
        @collection.institutions = @collection.institutions + [institution]
        institution.members = institution.members + [@collection]
        institution.save
      end
    #FIXME: Detect updates outside of collection form elsewhere...
    else
      if params[:collection][:members] == "add"
        params["batch_document_ids"].each do |pid|
          collection_query = Collection.find_with_conditions("hasCollectionMember_ssim:#{pid}", rows: '100000', fl: 'id' )
          collection_query.each do |collect_pid|
            collect_obj = Collection.find(collect_pid["id"])
            collect_obj.members.delete(ActiveFedora::Base.find(pid))
            collect_obj.save
          end
        end
      end
    end


    super
  end

  def create
    current_time = Time.now
    @collection[:date_created] =   [current_time.strftime("%Y-%m-%d")]
    #Contributor not being saved.... , {type: 'group', name: 'contributor', access: 'read'}
    @collection.permissions_attributes = [{type: 'group', name: 'admin', access: 'edit'}, {type: 'group', name: 'superuser', access: 'edit'}]
    if params[:collection][:institution_ids].present?
      params[:collection][:institution_ids].each do |institution_id|
        institution = Institution.find(institution_id)
        @collection.institutions = @collection.institutions + [institution]
        institution.members = institution.members + [@collection]

      end
    end

    super
  end

  def presenter_class
    MyCollectionPresenter
  end

  def form_class
    MyCollectionEditForm
  end

  def change_member_visibility
    collection = ActiveFedora::Base.find(params[:id])
    collection.members.each do |obj|
      if obj.visibility == 'restricted'
        obj.visibility = 'open'
        obj.save
      end
    end

    flash[:notice] = "Visibility of all objects was changed!"
    redirect_to request.referrer
  end

  def collection_params
    form_class.model_attributes(
        params.require(:collection).permit(:title, :description, :members, :date_created)
    )
  end

end