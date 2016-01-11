module CatalogHelper
  include Blacklight::CatalogHelperBehavior
# render the date in the catalog#index list view
  def index_date_value options={}
    document = options[:document]
    if document[:date_created_tesim]
      document[:date_created_tesim].first
    elsif document[:date_issued_tesim]
      document[:date_issued_tesim].first
    else
      nil
    end
  end
end