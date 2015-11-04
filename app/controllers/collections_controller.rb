class CollectionsController < ApplicationController
  include Sufia::CollectionsControllerBehavior
  before_action :verify_admin

  def create
    current_time = Time.now
    @collection[:date_created] =   [current_time.strftime("%Y-%m-%d")]
    @collection.permissions_attributes = [{type: 'group', name: 'admin', access: 'edit'}, {type: 'group', name: 'superuser', access: 'edit'}]
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
        params.require(:collection).permit(:institution, :title, :description, :contact_person, :address, :members, :date_created, :institution_url,
                                           subject: [], identifier: [], tag: [])
    )
  end

end