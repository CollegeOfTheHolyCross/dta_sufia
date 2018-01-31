module Wellcome
  class Z39

    def self.xsl_file
      File.join(app_root, 'config', 'mods.xsl')
    end

    def self.app_root
      return @app_root if @app_root
      @app_root = Rails.root if defined?(Rails) and defined?(Rails.root)
      @app_root ||= APP_ROOT if defined?(APP_ROOT)
      @app_root ||= '.'
    end

    def self.env
      return @env if @env
      #The following commented line always returns "test" in a rails c production console. Unsure of how to fix this yet...
      #@env = ENV["RAILS_ENV"] = "test" if ENV
      @env ||= Rails.env if defined?(Rails) and defined?(Rails.root)
      @env ||= 'development'
    end

    def self.config_path
      File.join(app_root, 'config', 'z39.yml')
    end


    def get_record(subfield, identifier)
      record = nil
      ZOOM::Connection.open('83.244.194.134', 210) do |conn|
        conn.database_name = 'INNOPAC'
        #conn.preferred_record_syntax = 'XML'
        record = conn.search("@attr 1=#{subfield} #{identifier}")
      end
      if record[0].present? && record[0].raw.present?
        return {:xml=>marc2xml(record[0].raw), :raw=>record[0].raw, :identifier=>identifier}
      else
        return {}
      end
    end

=begin
    def marc2xml(marc)
      val = MARC::Reader.decode marc
      marcxml = val.to_xml.to_s
      xsl = Dir.chdir(File.dirname('/home/bluewolf/dta/dta_sufia/public/mods.xsl')) { Nokogiri::XSLT.parse(File.read('/home/bluewolf/dta/dta_sufia/public/mods.xsl')) }
      doc = Nokogiri::XML(marcxml)
      new_xml = xsl.transform(doc)
      nok = Nokogiri::XML(new_xml.to_s).remove_namespaces!
    end
=end

    def marc2xml(marc)
      record = MARC::Reader.decode marc
      marcxml = record.to_xml.to_s
      return Nokogiri::XML(marcxml).remove_namespaces!
    end

    def marc2mods(marc)
      record = MARC::Reader.decode marc
      marcxml = record.to_xml.to_s
      modsxml = Nokogiri::XML(marcxml2mods(marcxml)).remove_namespaces!
      modsxml
    end

    def marcxml2mods(marcxml)
      xsl ||= Dir.chdir(File.dirname(self.xsl_file)) { Nokogiri::XSLT.parse(File.read(self.xsl_file)) }
      doc = Nokogiri::XML(marcxml)
      mods = xsl.transform(doc)
      mods.to_s
    end

  end
end