class CollectionsController < ApplicationController
  include Sufia::CollectionsControllerBehavior

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
  
  def new
  	if not current_user.admin?
  		redirect_to root_path
  	end
  end
end