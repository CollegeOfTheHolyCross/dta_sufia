class AboutsController < ApplicationController
  include DtaStaticBuilder

  before_action :get_latest_content

  before_action :set_nav_heading

  before_action :verify_superuser, only: [:new, :create, :edit, :update]

  def index
    @nav_items[0] = "What is this?"
  end

  def project
    @nav_items[1] = "Project Information"
  end

  def news
    @nav_items[2] = "News"
  end

  def team
    @nav_items[3] = "Our Team"
  end

  def board
    @nav_items[4] = "Advisory Board"
  end

  def policies
    @nav_items[5] = "Policies"
  end


  def contact
    @nav_items[6] = "Contact Us"
  end

  def edit
    @page = Abouts.find(params[:id])
  end

  def update
    @page = Abouts.find(params[:id])
    @page.destroy!
    @page = Abouts.new(page_params)
    #@page.update(page_params)

    if @page.save
      redirect_to about_path(:id => @page), notice: "Page was updated!"
    else
      redirect_to abouts_path, notice: "Could not update page"
    end
  end

  def new
    @page = Abouts.new
  end

  def create
    @page = Abouts.new(page_params)

    if @page.save
      redirect_to about_path(:id => @page.id)
    else
      #redirect_to post_path(:id => @post.id)
      redirect_to new_about_path, notice: "Could not create about page"
    end
  end

  def show
    if params[:id] == 'news'
      params.delete(:id)
      redirect_to posts_path
    else
      @page = Abouts.find(params[:id])
    end


  end

  def set_nav_heading
    @nav_section = 'About'
    @nav_items = []

    if current_user.present? and current_user.superuser?
      nav_items_raw = Abouts.all.order("link_order")
    else
      nav_items_raw = Abouts.where(:published=>true).order("link_order")
    end

    nav_items_raw.each do |nav_item|
      @nav_items << (ActionController::Base.helpers.link_to nav_item.title, about_path(:id=>nav_item))
    end

    #@nav_items << (ActionController::Base.helpers.link_to 'What is this?', about_path)
=begin
    @nav_items << (ActionController::Base.helpers.link_to 'Project Information', about_project_path)
    @nav_items << (ActionController::Base.helpers.link_to 'News', posts_path)
    @nav_items << (ActionController::Base.helpers.link_to 'Our Team', about_team_path)
    @nav_items << (ActionController::Base.helpers.link_to 'Advisory Board', about_board_path)
    @nav_items << (ActionController::Base.helpers.link_to 'Policies', about_policies_path)
    @nav_items << (ActionController::Base.helpers.link_to 'Contact Us', about_contact_path)
=end
  end

  def page_params
    params.require(:page).permit(:url_label, :title, :published, :content, :link_order)
  end


end