class MyGenericFilePresenter < Sufia::GenericFilePresenter
  self.terms = [:title,:alternative, :resource_type, :creator, :rights, :subject,  :genre, :summary, :contributor,
                :publisher, :date_created,  :date_issued, :temporal_coverage, :based_near,
                :identifier,
                :analog_format, :digital_format, :language,  :related_url, :tag, :flagged]
end