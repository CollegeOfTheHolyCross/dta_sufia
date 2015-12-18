class CollectionsController < ApplicationController
  include Sufia::CollectionsControllerBehavior
  before_action :verify_admin, except: :show #FIXME on change member


  def new
    institution_query = Institution.find_with_conditions("*:*", rows: '100000', fl: 'id,name_ssim' )
    @all_institutions = []
    institution_query.each { |term| @all_institutions << [term["name_ssim"].first, term["id"]] }
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