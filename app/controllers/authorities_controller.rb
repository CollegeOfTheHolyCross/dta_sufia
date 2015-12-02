require 'rdf'
require 'cgi'

class AuthoritiesController < ApplicationController
  def query
    s = params.fetch("q", "")
    e = params.fetch("e", "")
    hits =
        if params[:term] == "location" || params[:term] == "based_near"
          GeoNamesResource.find_location(s, e)
        elsif params[:term] == "lcsh_subject"
          LcshSubjectResource.find_location(s)
        elsif params[:term] == "homosaurus_subject"
          HomosaurusSubjectResource.find_location(s)
        elsif params[:term] == "other_subject"
          OtherSubjectResource.find_location(s)
        elsif params[:term] == "language"
          LanguageResource.find_location(s)
        else
          begin
            LocalAuthority.entries_by_term(params[:model], params[:term], s)
          rescue
            []
          end
        end
    render json: hits
  end
end