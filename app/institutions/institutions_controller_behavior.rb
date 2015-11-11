module InstitutionsControllerBehavior
  extend ActiveSupport::Concern
  include InstitutionsControllerBehaviorExtra

  included do
    include Sufia::Breadcrumbs

    before_action :filter_docs_with_read_access!, except: :show
    before_action :has_access?, except: :show
    before_action :build_breadcrumbs, only: [:edit, :show]

    self.search_params_logic += [:add_access_controls_to_solr_params, :add_advanced_parse_q_to_solr]

    layout "sufia-one-column"
  end

  def new
    super
    form
  end

  def edit
    super
    form
  end

  def show
    super
    presenter
  end

  protected

  def presenter
    @presenter ||= presenter_class.new(@institution)
  end

  def presenter_class
    InstitutionPresenter
  end

  def collection_member_search_builder_class
    ::SearchBuilder
  end

  def institution_params
    form_class.model_attributes(
        params.require(:institution).permit(:title, :description, :members, part_of: [],
                                           contributor: [], creator: [], publisher: [], date_created: [], subject: [],
                                           language: [], rights: [], resource_type: [], identifier: [], based_near: [],
                                           tag: [], related_url: [])
    )
  end

  def query_collection_members
    flash[:notice] = nil if flash[:notice] == "Select something first"
    params[:q] = params[:cq]
    super
  end

  def after_destroy(id)
    respond_to do |format|
      format.html { redirect_to sufia.dashboard_collections_path, notice: 'Collection was successfully deleted.' } #FIXME!!!
      format.json { render json: { id: id }, status: :destroyed, location: @collection }
    end
  end

  def form
    @form ||= form_class.new(@collection)
  end

  def form_class
    MyInstitutionEditForm
  end

  def _prefixes
    @_prefixes ||= super + ['catalog']
  end
end