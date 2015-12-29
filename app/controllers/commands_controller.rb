require 'rest_client'
require 'restclient/components'
require 'rack/cache'


class CommandsController < ApplicationController
  #before_action :verify_admin

  def update
=begin
    stdin, stdout, stderr = Open3.popen3('git pull origin master')
    stdin, stdout, stderr = Open3.popen3('bundle update')
    stdin, stdout, stderr = Open3.popen3('bundle exec rake assets:precompile --trace RAILS_ENV=production')
    stdin, stdout, stderr = Open3.popen3('bundle exec rake db:migrate RAILS_ENV="production"')
    stdin, stdout, stderr = Open3.popen3('touch tmp/restart.txt')
=end
`git pull origin master`
`bundle update`
`bundle exec rake assets:precompile --trace RAILS_ENV=production`
`bundle exec rake db:migrate RAILS_ENV="production"`
`touch tmp/restart.txt`

    respond_to do |format|
      format.html { render :text => "Updated. Application should restart soon." }
    end
  end

  def proxy
    url = params.fetch("q", "")
    r = RestClient.get url
    render json: r
  end

  def proxy_raw
    url = params.fetch("q", "")
    r = RestClient.get url, { accept: :json }
    r =  JSON.parse(r)
    render json: r
  end

  def reindex
    ActiveFedora::Base.reindex_everything
    render html: "<h1>Reindex sucessful</h1>"
  end
end