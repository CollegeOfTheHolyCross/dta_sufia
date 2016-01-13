class PostsController < ApplicationController
  include DtaStaticBuilder

  before_action :get_latest_content

  before_action :set_nav_heading

  before_action :verify_admin, only: [:new, :create, :edit, :update]

  def index
    if current_user.present? and current_user.admin?
      @posts = Posts.all.order("created DESC")
    else
      @posts = Posts.where(:published=>true).order("created DESC")
    end


  end

  def new
    @post = Posts.new

  end

  def edit
    @post = Posts.friendly.find(params[:id])
  end

  def update
    @post = Posts.friendly.find(params[:id])
    @post.update(post_params)

    if @post.save
      redirect_to post_path(:id => @post.slug), notice: "Post was updated!"
    else
      redirect_to posts_path, notice: "Could not update post"
    end
  end

  def create
    @post = Posts.new(post_params)
    current_time = Time.now

    @post.created_ym = [current_time.strftime("%Y-%m")]
    @post.created = current_time
    @post.updated = current_time
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
      redirect_to post_path(:id => @post.slug)
    else
      #redirect_to post_path(:id => @post.id)
      redirect_to new_post_path, notice: "Could not create post"
    end
  end

  def show
    @post = Posts.friendly.find(params[:id])

    respond_to do |format|
      format.html
      #format.nt { render body: @homosaurus.full_graph.dump(:ntriples), :content_type => Mime::NT }
      #format.jsonld { render body: @homosaurus.full_graph.dump(:jsonld, standard_prefixes: true), :content_type => Mime::JSONLD }
    end
  end


  def post_params
    params.require(:posts).permit(:content, :title, :published, :abstract)
  end

  def set_nav_heading
      @nav_section = 'About'
      @nav_items = []
      @nav_items << (ActionController::Base.helpers.link_to 'What is this?', about_path)
      @nav_items << (ActionController::Base.helpers.link_to 'Project Information', about_project_path)
      @nav_items << 'News'
      @nav_items << (ActionController::Base.helpers.link_to 'Our Team', about_team_path)
      @nav_items << (ActionController::Base.helpers.link_to 'Advisory Board', about_board_path)
      @nav_items << (ActionController::Base.helpers.link_to 'Policies', about_policies_path)
      @nav_items << (ActionController::Base.helpers.link_to 'Contact Us', about_contact_path)
  end
end