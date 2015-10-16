class CollectionsController < ApplicationController
  include Sufia::CollectionsControllerBehavior

  def presenter_class
    MyCollectionPresenter
  end

  def form_class
    MyCollectionEditForm
  end
end