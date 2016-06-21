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
    #ActiveFedora::Base.reindex_everything
    #ActiveFedora::Base.reindex_everything
    descendants = descendant_uris(ActiveFedora::Base.id_to_uri(''))
    descendants.shift # Discard the root uri
    descendants.each do |uri|
      #logger.debug "Re-index everything ... #{uri}"
      begin
      ActiveFedora::Base.find(ActiveFedora::Base.uri_to_id(uri)).update_index
      rescue
        #logger.error "Re-index everything error on ... #{uri}"
      end
    end

    render html: "<h1>Reindex sucessful</h1>"
  end



  def restart_resque
    ` /etc/init.d/resque stop`
    sleep(10)
    ` /etc/init.d/resque start`

    render html: "<h1>Resque Restarted</h1>"
  end

  def descendant_uris(uri)
    resource = Ldp::Resource::RdfSource.new(ActiveFedora.fedora.connection, uri)
    # GET could be slow if it's a big resource, we're using HEAD to avoid this problem,
    # but this causes more requests to Fedora.
    return [] unless Ldp::Response.rdf_source?(resource.head)
    immediate_descendant_uris = resource.graph.query(predicate: ::RDF::Vocab::LDP.contains).map { |descendant| descendant.object.to_s }
    all_descendants_uris = [uri]
    immediate_descendant_uris.each do |descendant_uri|
      all_descendants_uris += descendant_uris(descendant_uri)
    end
    all_descendants_uris
  end

  def admin_actions
=begin
    if !verify_superuser
      raise "Access Not Allowed"
    end
=end
  end
end