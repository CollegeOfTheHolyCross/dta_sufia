class MyGenericFilePresenter < Sufia::GenericFilePresenter
  self.terms = [:resource_type, :title,:alternative, :creator, :contributor, :summary,
                :tag, :rights, :publisher, :date_created, :subject, :language,
                :identifier, :based_near, :related_url,
                :analog_format, :digital_format, :genre, :date_issued, :temporal_coverage]
end