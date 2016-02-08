class DownloadsController < ApplicationController
  include Sufia::DownloadsControllerBehavior

  def authorize_download!
    if params["file"].present? and params["file"] == 'thumbnail'
      return true
    else
      authorize! :download, file
    end
  end

  #FIXME: This is cached in sufia... means that users can't see files changed sometimes...
  def file
    #load_file
    @file ||= load_file
  end

  def send_content
    if file.mime_type == "application/pdf"
      self.status = 200
      response.headers['Content-Length'] = file.size.to_s
      response.headers['Content-Disposition'] = "inline;filename=#{asset.label.gsub(/[,;]/, '')}.pdf"
      render body: file.content, content_type: "application/pdf"
    else
      super
    end

  end

end