class MyCollectionEditForm < MyCollectionPresenter
  include HydraEditor::Form
  include HydraEditor::Form::Permissions

  self.required_fields = [:institutions, :title, :description]
end