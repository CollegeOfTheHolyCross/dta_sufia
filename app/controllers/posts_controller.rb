class PostsController < ApplicationController
  include DtaStaticBuilder

  before_action :get_latest_content

  before_action :set_nav_heading

  def index
    @posts = Posts.all

  end

  def new
    @post = Posts.new

  end

  def create
    @post = Posts.new(news_params)
    @post.created = Time.now
    @post.updated = Time.now
    @post.user = current_user.email

=begin
    if params[:homosaurus][:broader_ids].present?
      params[:homosaurus][:broader_ids].each do |broader|
        if broader.present?
          broader_object = Homosaurus.find(broader)
          @homosaurus.broader = @homosaurus.broader + [broader_object]
          broader_object.narrower = broader_object.narrower + [@homosaurus]
          broader_object.save
        end
      end
    end
=end


    if @post.save
      redirect_to new_path(:id => @post.id)
    else
      redirect_to new_new_path
    end
  end

  def show
    @post = Posts.find(params[:id])

    respond_to do |format|
      format.html
      #format.nt { render body: @homosaurus.full_graph.dump(:ntriples), :content_type => Mime::NT }
      #format.jsonld { render body: @homosaurus.full_graph.dump(:jsonld, standard_prefixes: true), :content_type => Mime::JSONLD }
    end
  end


  def news_params
    params.require(:posts).permit(:content, :title, :identifier, :published, :pname)
  end

  def set_nav_heading
      @nav_section = 'About'
      @nav_items = []
      @nav_items << (ActionController::Base.helpers.link_to 'What is this?', about_path)
      @nav_items << (ActionController::Base.helpers.link_to 'Project Information', about_project_path)
      @nav_items << (ActionController::Base.helpers.link_to 'News', posts_path)
      @nav_items << (ActionController::Base.helpers.link_to 'Our Team', about_team_path)
      @nav_items << (ActionController::Base.helpers.link_to 'Advisory Board', about_board_path)
      @nav_items << (ActionController::Base.helpers.link_to 'Policies', about_policies_path)
      @nav_items << (ActionController::Base.helpers.link_to 'Contact Us', about_contact_path)
  end
end