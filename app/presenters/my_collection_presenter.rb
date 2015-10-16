class MyCollectionPresenter < Sufia::CollectionPresenter
  self.terms = [:institution, :title, :description, :related_url, :address, :contact_person,
                :tag, :subject, :identifier]
end