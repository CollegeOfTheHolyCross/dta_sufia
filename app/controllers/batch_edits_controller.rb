class BatchEditsController < ApplicationController
  include Hydra::BatchEditBehavior
  include GenericFileHelper
  include Sufia::BatchEditsControllerBehavior

  def terms
    MyBatchEditForm.terms
  end

  #FIXME: The below is broken in this version of Sufia for batch uploads

  #In this case, Sufia assumes are fields are multi-valued. This function and initialize fields has a hack to
  #allow for single value strings rather than assuming the values are an array.
  def edit
    @generic_file = ::GenericFile.new
    @generic_file.depositor = current_user.user_key
    @terms = terms - [:title, :format, :resource_type]

    h = {}
    @names = []
    permissions = []

    # For each of the files in the batch, set the attributes to be the concatination of all the attributes
    batch.each do |doc_id|
      gf = ::GenericFile.load_instance_from_solr(doc_id)
      terms.each do |key|
        h[key] ||= []
        if gf.send(key).instance_of?String
          h[key] = gf.send(key)
        else
          h[key] = (h[key] + gf.send(key)).uniq
        end

      end
      @names << gf.to_s
      permissions = (permissions + gf.permissions).uniq
    end

    initialize_fields(h, @generic_file)

    @generic_file.permissions_attributes = [{ type: 'group', name: 'public', access: 'read' }]
  end

  def initialize_fields(attributes, file)
    terms.each do |key|
       if attributes[key].instance_of?String
         # if value is empty, we create an one element array to loop over for output
         file[key] = attributes[key].empty? ? '' : attributes[key]
       else
         # if value is empty, we create an one element array to loop over for output
         file[key] = attributes[key].empty? ? [''] : attributes[key]
       end
    end
  end

  #In Sufia::BatchEditsControllerBehavior, this method has a hard coded "Forms::BatchEditForm" rather than using the
  #overriden local form class.
  def generic_file_params
    file_params = params[:generic_file] || ActionController::Parameters.new
    MyBatchEditForm.model_attributes(file_params)
  end
end