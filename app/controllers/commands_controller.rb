class CommandsController < ApplicationController
  before_action :verify_admin

  def update
    stdin, stdout, stderr = Open3.popen3('git pull origin master')
    stdin, stdout, stderr = Open3.popen3('bundle update')
    stdin, stdout, stderr = Open3.popen3('bundle exec rake assets:precompile --trace RAILS_ENV=production')
    stdin, stdout, stderr = Open3.popen3('bundle exec rake db:migrate RAILS_ENV="production')
    stdin, stdout, stderr = Open3.popen3('touch tmp/restart.txt')

    respond_to do |format|
      format.html { render :text => "Updated. Application should restart soon." }
    end
  end
end