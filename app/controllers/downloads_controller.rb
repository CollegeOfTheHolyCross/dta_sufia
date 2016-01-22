class DownloadsController < ApplicationController
  include Sufia::DownloadsControllerBehavior

  #FIXME: This is cached in sufia... means that users can't see files changed sometimes...
  def file
    #load_file
    @file ||= load_file
  end

  def send_content
    if file.mime_type == "application/pdf"
      self.status = 200
      response.headers['Content-Length'] = file.size.to_s
      render body: file.content, content_type: "application/pdf", content_length: file.size.to_s
    else
     super
    end
  end

end