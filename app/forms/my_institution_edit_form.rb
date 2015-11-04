class MyInstitutionEditForm < MyInstitutionPresenter
  include HydraEditor::Form
  include HydraEditor::Form::Permissions

  self.required_fields = [:title, :description]
end