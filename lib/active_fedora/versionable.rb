module ActiveFedora
  module Versionable
    extend ActiveSupport::Concern
    extend Deprecation

    included do
      class_attribute :versionable
    end

    module ClassMethods
      def has_many_versions
        Deprecation.warn Versionable, "has_many_versions is deprecated and will be removed in ActiveFedora 11."
        # self.versionable = true
      end
    end

    def model_type
      if respond_to?(:metadata)
        metadata.ldp_source.graph.query(predicate: ::RDF.type).objects
      else
        resource.query(subject: resource.rdf_subject, predicate: ::RDF.type).objects
      end
    end

    # Returns an array of ActiveFedora::VersionsGraph::ResourceVersion objects.
    # Excludes auto-snapshot versions from Fedora.
    def versions(reload = false)
      if reload
        @versions = ActiveFedora::VersionsGraph.new << ::RDF::Reader.for(:ttl).new(versions_request)
      else
        @versions ||= ActiveFedora::VersionsGraph.new << ::RDF::Reader.for(:ttl).new(versions_request)
      end
    end

    def create_version
      resp = ActiveFedora.fedora.connection.post(versions_uri, nil, slug: version_name)
      @versions = nil
      resp.success?
    end

    # Queries Fedora to figure out if there are versions for the resource.
    def has_versions?
      ActiveFedora.fedora.connection.head(versions_uri)
      true
    rescue Ldp::NotFound
      false
    end

    def restore_version(label)
      resp = ActiveFedora.fedora.connection.patch(versions.with_label(label).uri, nil)
      @versions = nil
      reload
      refresh_attributes if respond_to?("refresh_attributes")
      resp.success?
    end

    private

    def versions_request
      return '' unless has_versions?
      resp = ActiveFedora.fedora.connection.get(versions_uri)
      raise ActiveFedoraError, status_message(resp) unless resp.success?
      raise ActiveFedoraError, bad_headers(resp) unless resp.headers['content-type'].include?('text/turtle')
      resp.body
    end

    def versions_uri
      uri + '/fcr:versions'
    end

    def version_name
      if versions.all.empty?
        "version1"
      else
        "version" + (versions.all.count + 1).to_s
      end
    end

    def status_message(response)
      "Unexpected return value #{response.status} when retrieving datastream content at #{uri}\n\t#{response.body}"
    end

    def bad_headers(response)
      "Unknown response format. Got '#{response.headers['content-type']}', but was expecting 'text/turtle'"
    end
  end
end