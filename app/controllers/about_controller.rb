class AboutController < ApplicationController
  include DtaStaticBuilder

  before_action :get_latest_content

  before_action :set_nav_heading

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