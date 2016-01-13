module DtaStaticBuilder
  def get_latest_content
    @latest_documents = GenericFile.find_with_conditions("is_public_ssi:true", rows: '3', :sort => 'date_uploaded_dtsi desc' )
    @recent_posts = Posts.order("created DESC").limit(3)
  end
end