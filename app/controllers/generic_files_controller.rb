class GenericFilesController < ApplicationController
  include Sufia::Controller
  include Sufia::FilesControllerBehavior

  self.presenter_class = MyGenericFilePresenter
  self.edit_form_class = MyFileEditForm

  #Needed because it attempts to load from Solr in: load_resource_from_solr of Sufia::FilesControllerBehavior
  skip_load_and_authorize_resource :only=> :create

  def new
    super
    @form = edit_form
    @selectable_collection = []
    @selectable_collection = Collection.all #FIXME
  end

  def create
    if params.key?(:upload_type) and params[:upload_type] == 'single'
      return json_error("Error! No file to save") unless params.key?(:filedata)
      Batch.find_or_create(params[:batch_id])
      #Actor sets @generic_file to blank...
      @generic_file = ::GenericFile.new
      @generic_file.depositor = current_user.user_key
      @generic_file.permissions_attributes = [{ type: 'group', name: 'public', access: 'read' }, {type: 'group', name: 'admin', access: 'edit'}, {type: 'group', name: 'superuser', access: 'edit'}]
      @generic_file.title = [params[:generic_file][:title]]
      @generic_file.label = params[:generic_file][:title]

      actor.create_metadata(params[:batch_id])
      file = params[:filedata]
      actor.create_content(file, file.original_filename, file_path, file.content_type, params[:collection])
      update_metadata

      #@generic_file.edit_groups += ['admin', 'superuser']

      redirect_to sufia.dashboard_files_path, notice: render_to_string(partial: 'generic_files/asset_updated_flash', locals: { generic_file: @generic_file })

      #redirect_to sufia.dashboard_files_path(:utf8=>'✓',:sort=>'date_uploaded_dtsi+desc'), notice:
                                                                       #render_to_string(partial: 'generic_files/asset_updated_flash', locals: { generic_file: @generic_file })
      #redirect_to sufia.edit_generic_file_path(tab: params[:redirect_tab]), notice:
                                                                              #render_to_string(partial: 'generic_files/asset_updated_flash', locals: { generic_file: @generic_file })
    else
      create_from_upload(params)
    end
  end


  
end