module DtaStaticBuilder
  def get_latest_content
    @latest_documents = GenericFile.find_with_conditions("is_public_ssi:true", rows: '4', :sort => 'date_uploaded_dtsi desc' )

    @recent_posts = Posts.where(:published=>true).order("created DESC").limit(3)
=begin
    if @recent_posts.present?
      @recent_posts.limit(3)
    else
      @recent_posts = []
    end
=end



  end
end