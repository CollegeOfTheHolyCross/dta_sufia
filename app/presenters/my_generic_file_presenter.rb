class MyGenericFilePresenter < Sufia::GenericFilePresenter
  self.terms = [:title,:alternative, :creator, :contributor, :date_created,  :date_issued,
                :temporal_coverage, :based_near,
                :homosaurus_subject, :lcsh_subject, :other_subject,
                :flagged,:resource_type,:genre, :analog_format, :digital_format, :description,:toc, :language,
                :publisher,:related_url, :rights, :hosted_elsewhere, :is_shown_at] #, :preview,:identifier :summary
end