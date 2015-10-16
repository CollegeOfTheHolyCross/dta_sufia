class MyCollectionPresenter < Sufia::CollectionPresenter
  self.terms = [:institution, :title, :description, :institution_url, :address, :contact_person,
                :tag, :subject, :identifier]
end