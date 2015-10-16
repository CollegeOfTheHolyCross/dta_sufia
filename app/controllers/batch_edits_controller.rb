class BatchEditsController < ApplicationController
  include Hydra::BatchEditBehavior
  include GenericFileHelper
  include Sufia::BatchEditsControllerBehavior

  def terms
    MyBatchEditForm.terms
  end
end