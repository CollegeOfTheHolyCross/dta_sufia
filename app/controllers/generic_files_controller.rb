class GenericFilesController < ApplicationController
  include Sufia::Controller
  include Sufia::FilesControllerBehavior

  self.presenter_class = MyGenericFilePresenter
  self.edit_form_class = MyFileEditForm

  #Needed because it attempts to load from Solr in: load_resource_from_solr of Sufia::FilesControllerBehavior
  skip_load_and_authorize_resource :only=> :create

  def new
    super

    if session[:unsaved_generic_file].present?
      begin
        @generic_file.update(session[:unsaved_generic_file])
      rescue => ex
      end
      session[:unsaved_generic_file] = nil
    end

    @form = edit_form

    @selectable_collection = []
    @selectable_collection = Collection.all #FIXME
  end

  def create
    if params.key?(:upload_type) and params[:upload_type] == 'single'
      if !validate_metadata(params)
        params[:generic_file][:title] = [params[:generic_file][:title]]
        session[:unsaved_generic_file] = params[:generic_file]
        redirect_to sufia.new_generic_file_path
      else
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
      end


    else
      create_from_upload(params)
    end
  end

  def validate_metadata(params)
    if !params.key?(:filedata)
      flash[:error] = 'No file was uploaded!'

      return false
    end

    params[:generic_file][:date_created].each do |date_created|
      if date_created.present? and Date.edtf(date_created).nil?
        flash[:error] = 'Incorrect format for date_created. Please check the EDTF guidelines.'
        return false
      end
    end
    return true
  end

  # this is provided so that implementing application can override this behavior and map params to different attributes
  def update_metadata
    if params[:generic_file][:lcsh_subject].present? and params[:generic_file][:other_subject].present?
      params[:generic_file][:other_subject] += params[:generic_file][:lcsh_subject]
      params[:generic_file].delete(:lcsh_subject)
    end
    file_attributes = edit_form_class.model_attributes(params[:generic_file])
    actor.update_metadata(file_attributes, params[:visibility])
  end


  
end