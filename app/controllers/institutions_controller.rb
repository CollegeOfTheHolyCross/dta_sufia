class InstitutionsController < CatalogController
  include DtaStaticBuilder

  before_action :verify_admin, except: [:public_index, :public_show]
  include Blacklight::Configurable
  include Blacklight::SearchHelper

  copy_blacklight_config_from(CatalogController)

  before_filter :remove_unwanted_views, :only => [:public_index]

  # remove collection facet and collapse others
  before_filter :relation_base_blacklight_config, :only => [:public_show]


  def enforce_show_permissions
    #DO NOTHING
  end
  # remove grid view from blacklight_config for index view
  def remove_unwanted_views
    blacklight_config.view.delete(:gallery)
    blacklight_config.view.delete(:masonry)
    blacklight_config.view.delete(:slideshow)
  end

  # Blacklight uses #search_action_url to figure out the right URL for
  # the global search box
  def search_action_url options = {}
    catalog_index_url(options.except(:controller, :action))
  end
  helper_method :search_action_url

  def index
    #@terms = Homosaurus.all.sort_by { |term| term.preferred_label }
    #@terms = Homosaurus.all
    @institutions = Institution.find_with_conditions("*:*", rows: '1000', fl: 'id,name_ssim' )
    @institutions = @institutions.sort_by { |term| term["name_ssim"].first }
  end

  def show
    @institution = Institution.find(params[:id])

    respond_to do |format|
      format.html
      #format.nt { render body: @homosaurus.full_graph.dump(:ntriples), :content_type => Mime::NT }
      #format.jsonld { render body: @homosaurus.full_graph.dump(:jsonld, standard_prefixes: true), :content_type => Mime::JSONLD }
    end
  end

  def public_show
    @nav_li_active = 'explore'
    @show_response, @document = fetch(params[:id])
    @institution_title = @document[:institution_name_ssim].first

    # get the response for collection objects
    @collex_response, @collex_documents = search_results({:f => {'active_fedora_model_ssi' => 'Collection','institution_pid_ssi' => params[:id]},:rows => 100, :sort => 'title_info_ssort asc'}, search_params_logic)

    # add params[:f] for proper facet links
    params[:f] = {blacklight_config.institution_field => [@institution_title]}

    # get the response for the facets representing items in collection
    (@response, @document_list) = search_results({:f => params[:f]}, search_params_logic)

    respond_to do |format|
      format.html
    end

  end

  def public_index
    @nav_li_active = 'explore'
    self.search_params_logic += [:institutions_filter]
    #solr_parameters[:fq] << "-active_fedora_model_ssi:\"Collection\""
    (@response, @document_list) = search_results({:f => {'active_fedora_model_ssi' => 'Institution'},:rows => 100, :sort => 'title_primary_ssort asc'}, search_params_logic)
    #params[:per_page] = params[:per_page].presence || '50'
    #(@response, @document_list) = search_results(params, search_params_logic)

    params[:view] = 'list'
    params[:sort] = 'title_primary_ssort asc'

    respond_to do |format|
      format.html
    end
  end

  def new
    @institution = Institution.new
    collection_query = Collection.find_with_conditions("*:*", rows: '100000', fl: 'id,title_tesim' )
    @all_collections = []
    collection_query.each { |term| @all_collections << [term["title_tesim"], term["id"]] }

  end

  def create
    @institution = Institution.new(institution_params)

    current_time = Time.now
    @institution.date_created =   current_time.strftime("%Y-%m-%d")
    @institution.permissions_attributes = [{ type: 'group', name: 'public', access: 'read' }, {type: 'group', name: 'admin', access: 'edit'}, {type: 'group', name: 'superuser', access: 'edit'}]
    @institution.visibility = 'open'

    if params.key?(:filedata)
      file = params[:filedata]
      @institution.add_file(file, path: 'content', original_name: file.original_filename, mime_type: file.content_type)
    end

=begin
    if params[:homosaurus][:broader_ids].present?
      params[:homosaurus][:broader_ids].each do |broader|
        if broader.present?
          broader_object = Homosaurus.find(broader)
          @homosaurus.broader = @homosaurus.broader + [broader_object]
          broader_object.narrower = broader_object.narrower + [@homosaurus]
          broader_object.save
        end
      end
    end
=end


    if @institution.save
      redirect_to institution_path(:id => @institution.id)
    else
      redirect_to new_institution_path
    end
  end

  def edit
    @institution = Institution.find(params[:id])
    collection_query = Collection.find_with_conditions("*:*", rows: '100000', fl: 'id,title_tesim' )
    @all_collections = []
    collection_query.each { |term| @all_collections << [term["title_tesim"], term["id"]] }
  end

  def update
    @institution = Institution.find(params[:id])
    @institution.update(institution_params)

    if params.key?(:filedata)
      file = params[:filedata]
      @institution.add_file(file, path: 'content', original_name: file.original_filename, mime_type: file.content_type)
    end


=begin
    if params[:homosaurus][:broader_ids].present?
      params[:homosaurus][:broader_ids].each do |broader|
        if broader.present?
          broader_object = Homosaurus.find(broader)
          @homosaurus.broader = @homosaurus.broader + [broader_object]
          broader_object.narrower = broader_object.narrower + [@homosaurus]
          broader_object.save
        end
      end
    end
=end


    if @institution.save
      redirect_to institution_path(:id => @institution.id), notice: "Institution was updated!"
    else
      redirect_to new_institution_path
    end
  end


  def institution_params
    params.require(:institution).permit(:name, :description, :contact_person, :address, :email, :phone, :institution_url)
  end
end