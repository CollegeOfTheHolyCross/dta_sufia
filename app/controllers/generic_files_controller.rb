class GenericFilesController < ApplicationController
  include Sufia::Controller
  include Sufia::FilesControllerBehavior
  include Sufia::Lockable
  include DtaStaticBuilder

  before_action :get_latest_content

  before_action :verify_contributor, except: [:show] #FIXME: Added show for now... but need to remove that...

  self.presenter_class = MyGenericFilePresenter
  self.edit_form_class = MyFileEditForm

  #Needed because it attempts to load from Solr in: load_resource_from_solr of Sufia::FilesControllerBehavior
  skip_load_and_authorize_resource :only=> [:create, :swap_visibility, :show] #FIXME: Why needed for swap visibility exactly?

  # routed to /files/:id
  def show
    #super
    if @generic_file.visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED and !current_or_guest_user.contributor?
      redirect_to root_path
    else
      respond_to do |format|
        format.html do
          @events = @generic_file.events(100)
          @presenter = presenter
          @audit_status = audit_service.human_readable_audit_status
          @show_response, @document = fetch(params[:id])
        end
        format.endnote { render text: @generic_file.export_as_endnote }
      end
    end
  end

  def new
    super

    if session[:unsaved_generic_file].present?
      begin
        @generic_file.update(ActiveSupport::HashWithIndifferentAccess.new(session[:unsaved_generic_file]))
      rescue => ex
      end
      session[:unsaved_generic_file] = nil
    end

    @form = edit_form

    #@selectable_collection = []
=begin
    @selectable_collection = Collection.all #FIXME
    @selectable_collection = @selectable_collection.sort_by { |collection| collection.title.first }
=end

    #term_query = Collection.find_with_conditions("*:*", rows: '10000', fl: 'id,title_tesim' )
    #term_query = term_query.sort_by { |term| term["title_tesim"].first }
    @selectable_collection = []
    #term_query.each { |term| @selectable_collection << [term["title_tesim"].first, term["id"]] }

    term_query = Institution.find_with_conditions("*:*", rows: '10000', fl: 'id,name_ssim' )
    term_query = term_query.sort_by { |term| term["name_ssim"].first }
    @selectable_institution = []
    term_query.each { |term| @selectable_institution << [term["name_ssim"].first, term["id"]] }

    #@selectable_collection = @selectable_collection
  end



  def create
    if params.key?(:upload_type) and params[:upload_type] == 'internetarchive'
      #result = Resque.enqueue(InternetArchive::DtaBooks, :collection_id=>params[:collection_internet_archive], :institution_id=>params[:institution_internet_archive], :depositor=>current_user.user_key)
      collection_id = 'digitaltransgenderarchive'
      @url = "http://archive.org/advancedsearch.php?q=collection%3A%22#{collection_id}%22&fl%5B%5D=identifier&output=json&rows=10000"
      list_response = Typhoeus::Request.get(@url)
      list_response_as_json = JSON.parse(list_response.body)
      list_response_as_json["response"]["docs"].each do |result|
        result = Resque.enqueue(InternetArchive::DtaSingleBook, :collection_id=>params[:collection_internet_archive], :institution_id=>params[:institution_internet_archive], :depositor=>current_user.user_key, :ia_id=>result['identifier'])
      end
      #InternetArchiveBooks.perform_async(params[:collection_internet_archive], params[:institution_internet_archive], current_user.user_key)
      #redirect_to sufia.dashboard_files_path, notice: render_to_string(partial: 'generic_files/asset_updated_flash', locals: { generic_file: @generic_file })
      flash[:notice] = "Internet archive ingest started in background!"
      redirect_to sufia.dashboard_files_path
    elsif params.key?(:upload_type) and params[:upload_type] == 'single'
      if !validate_metadata(params, 'create')

        if params[:generic_file][:other_subject].present?
          params[:generic_file][:other_subject].collect!{|x| x.strip || x }
          params[:generic_file][:other_subject].reject!{ |x| x.blank? }
        end

        #FIXME: This should be done elsewhere...
        if params[:generic_file][:lcsh_subject].present? and !params[:generic_file][:other_subject].nil?
          params[:generic_file][:other_subject] += params[:generic_file][:lcsh_subject]
          params[:generic_file].delete(:lcsh_subject)
        end

        if params[:generic_file][:homosaurus_subject].present? and !params[:generic_file][:other_subject].nil?
          params[:generic_file][:other_subject] += params[:generic_file][:homosaurus_subject]
          params[:generic_file].delete(:homosaurus_subject)
        end

        if params[:generic_file][:homosaurus_subject].present? and params[:generic_file][:lcsh_subject].present? and params[:generic_file][:other_subject].nil?
          params[:generic_file][:lcsh_subject] += params[:generic_file][:homosaurus_subject]
          params[:generic_file].delete(:homosaurus_subject)
        end
        #END FIXME

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

        if params[:generic_file][:hosted_elsewhere] != "0"
          if params.key?(:filedata)
            file = params[:filedata]
            img = Magick::Image.read(file.path()).first
            img = Magick::Image.from_blob( img.to_blob { self.format = "jpg" } ).first

            if File.extname(file.original_filename) == '.pdf'
              thumb = img.resize_to_fit(500,600) #338,493
            else
              thumb = img.resize_to_fit(500,600) #FIXME?
            end



            actor.create_content(StringIO.open(thumb.to_blob), File.basename(file.original_filename,File.extname(file.original_filename)), file_path, 'image/jpeg', params[:collection])
          else
            saved = actor.save_characterize_and_record_committer
            if saved
              actor.add_file_to_collection(params[:collection])
            end

          end
        else
          file = params[:filedata]
          actor.create_content(file, file.original_filename, file_path, file.content_type, params[:collection])
        end

        #FIXME
        acquire_lock_for(params[:institution]) do
          institution = Institution.find(params[:institution])
          institution.files << [@generic_file]
          institution.save
        end

        update_metadata
        @generic_file.update_index

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


  def validate_metadata(params, type)
    if !params.key?(:filedata) && params[:generic_file][:hosted_elsewhere] != "1" && type != 'update'
      flash[:error] = 'No file was uploaded!'

      return false
    end

    params[:generic_file][:date_created].each do |date_created|
      if date_created.present? and Date.edtf(date_created).nil?
        flash[:error] = 'Incorrect format for date created. Please check the EDTF guidelines.'
        return false
      end
    end

    params[:generic_file][:date_issued].each do |date_issued|
      if date_issued.present? and Date.edtf(date_issued).nil?
        flash[:error] = 'Incorrect format for date issued. Please check the EDTF guidelines.'
        return false
      end
    end

    params[:generic_file][:temporal_coverage].each do |temporal_coverage|
      if temporal_coverage.present? and Date.edtf(temporal_coverage).nil?
        flash[:error] = 'Incorrect format for temporal coverage. Please check the EDTF guidelines.'
        return false
      end
    end

    params[:generic_file][:language].each do |language|
      if language.present? and !language.match(/id\.loc\.gov\/vocabulary\/iso639\-2\/\w\w\w/)
        flash[:error] = 'Language was not selected from the autocomplete?'
        return false
      end
    end
    return true
  end

  def regenerate
    Sufia.queue.push(CharacterizeJob.new(params[:id]))
    flash[:notice] = "Thumbnail scheduled to be regenerated!"
    redirect_to sufia.dashboard_files_path
  end

  def swap_visibility
    #update_visibility
    obj = ActiveFedora::Base.find(params[:id])
    if obj.visibility == 'restricted'
      obj.visibility = 'open'
    else
      obj.visibility = 'restricted'
    end
    obj.save
    flash[:notice] = "Visibility of object was changed!"
    redirect_to request.referrer
  end

  # this is provided so that implementing application can override this behavior and map params to different attributes
  def update_metadata
=begin
    if params[:generic_file][:lcsh_subject].present? and params[:generic_file][:other_subject].present?
      params[:generic_file][:other_subject] += params[:generic_file][:lcsh_subject]
      params[:generic_file].delete(:lcsh_subject)
    end
=end
    if params[:generic_file][:other_subject].present?
      params[:generic_file][:other_subject].collect!{|x| x.strip || x }
      params[:generic_file][:other_subject].reject!{ |x| x.blank? }
    end

    if params[:generic_file][:lcsh_subject].present? and !params[:generic_file][:other_subject].nil?
      params[:generic_file][:other_subject] += params[:generic_file][:lcsh_subject]
      params[:generic_file].delete(:lcsh_subject)
    end

    if params[:generic_file][:homosaurus_subject].present? and !params[:generic_file][:other_subject].nil?
      params[:generic_file][:other_subject] += params[:generic_file][:homosaurus_subject]
      params[:generic_file].delete(:homosaurus_subject)
    end

    if params[:generic_file][:homosaurus_subject].present? and params[:generic_file][:lcsh_subject].present? and params[:generic_file][:other_subject].nil?
      params[:generic_file][:lcsh_subject] += params[:generic_file][:homosaurus_subject]
      params[:generic_file].delete(:homosaurus_subject)
    end

    if params[:generic_file][:title].present?
      params[:generic_file][:title] = [params[:generic_file][:title]]
    end

    if params[:generic_file][:creator].present?
      params[:generic_file][:creator].collect!{|x| x.strip || x }
      params[:generic_file][:creator].reject!{ |x| x.blank? }
    end

    if params[:generic_file][:contributor].present?
      params[:generic_file][:contributor].collect!{|x| x.strip || x }
      params[:generic_file][:contributor].reject!{ |x| x.blank? }
    end

    file_attributes = edit_form_class.model_attributes(params[:generic_file])
    actor.update_metadata(file_attributes, params[:visibility])
  end

  def edit
    object = GenericFile.find(params[:id])
    term_query = Institution.find_with_conditions("*:*", rows: '10000', fl: 'id,name_ssim' )
    term_query = term_query.sort_by { |term| term["name_ssim"].first }
    @selectable_institution = []
    term_query.each { |term| @selectable_institution << [term["name_ssim"].first, term["id"]] }

    if object.institutions.present?
      @institution_id = object.institutions.first.id
      term_query = Collection.find_with_conditions("isMemberOfCollection_ssim:#{@institution_id}", rows: '10000', fl: 'id,title_tesim' )
      term_query = term_query.sort_by { |term| term["title_tesim"].first }
      @selectable_collection = []
      term_query.each { |term| @selectable_collection << [term["title_tesim"].first, term["id"]] }
      @collection_id = object.collections.first.id if object.collections.present?
    else
      @selectable_collection = []
    end

    super
  end

  def update
    #FIXME
    if params.key? :generic_file and !params[:generic_file][:permissions_attributes]
      if !validate_metadata(params, 'update')
        redirect_to sufia.edit_generic_file_path(:id => @generic_file.id), notice: "An error prevented this item from being updated."
      else

        super
        #@generic_file = GenericFile.find(params[:id])

        @generic_file.institutions.each do |inst|
          acquire_lock_for(inst.id) do
            inst.reload
            inst.files.delete(@generic_file)
          end
        end

        @generic_file.collections.each do |coll|
          acquire_lock_for(coll.id) do
            coll.reload
            coll.members.delete(@generic_file)
          end
        end

        @generic_file.institutions = []
        @generic_file.collections = []

        #FIXME
        acquire_lock_for(params[:collection]) do
          collection = Collection.find(params[:collection])
          collection.members << [@generic_file]
          collection.save
        end

        acquire_lock_for(params[:institution]) do
          institution = Institution.find(params[:institution])
          institution.files << [@generic_file]
          institution.save
        end
        
        @generic_file = GenericFile.find(@generic_file.id)
        @generic_file.update_index
        #raise params[:institution]
      end
    else
      super
    end




  end


  
end