module Sufia
  module DownloadsControllerBehavior
    extend ActiveSupport::Concern
    include Hydra::Controller::DownloadBehavior

    #This is cached in sufia... means that users can't see files changed
    def file
      #load_file
      @file ||= load_file
    end
    def send_file_contents
      self.status = 200
      prepare_file_headers
      if file.mime_type == "application/pdf"
        response.stream.write file.content
      else
        stream_body file.stream
      end
    end



    def file_name
      if !params[:file] || params[:file] == self.class.default_file_path
        params[:filename] || asset.label
      else
        params[:file]
      end
    end
  end
end