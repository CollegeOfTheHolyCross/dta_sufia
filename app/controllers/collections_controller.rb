class CollectionsController < ApplicationController
  include Sufia::CollectionsControllerBehavior
  before_action :verify_admin

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

    @collection.institutions.each do |institution|
      institution.members.delete(@collection)
      institution.save
    end
    @collection.reload
    @collection.institutions = []

    if params[:collection][:institution_ids].present?
      params[:collection][:institution_ids].each do |institution_id|
        institution = Institution.find(institution_id)
        @collection.institutions = @collection.institutions + [institution]
        institution.members = institution.members + [@collection]
        institution.save
      end
    end


    super
  end

  def create
    current_time = Time.now
    @collection[:date_created] =   [current_time.strftime("%Y-%m-%d")]
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

  def collection_params
    form_class.model_attributes(
        params.require(:collection).permit(:title, :description, :members, :date_created)
    )
  end

end