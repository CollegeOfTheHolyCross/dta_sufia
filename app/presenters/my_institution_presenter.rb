class MyInstitutionPresenter < Sufia::CollectionPresenter
  self.model_class = ::Institution
  self.terms = [:title, :description, :institution_url, :address, :contact_person]
end