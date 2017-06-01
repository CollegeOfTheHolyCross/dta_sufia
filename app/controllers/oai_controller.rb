class OaiController < ApplicationController
  ListRecord = Struct.new(:id, :date, :dtarecord, :collections)
  SetRecord = Struct.new(:id, :date, :title, :description)
  ROWS = 100

  def index
    @verb = params.delete(:verb)
    raise("Unsupported verb: #{@verb}") unless @verb == 'ListRecords' || @verb == 'ListSets' || @verb == 'GetRecord'

    @metadata_prefix = params.delete(:metadataPrefix) || 'dta_dc'
    raise("Unsupported metadataPrefix: #{@metadata_prefix}") unless @metadata_prefix == 'dta_dc'

    resumption_token = params.delete(:resumptionToken) || '0'
    raise("Unsupported resumptionToken: #{resumption_token}") unless resumption_token =~ /^\d*$/
    @start = resumption_token.to_i

    identifier = params.delete(:identifier) || ''

    unsupported = params.keys - %w(action controller format)
    raise("Unsupported params: #{unsupported}") unless unsupported.empty?

    @response_date = Time.now.strftime('%FT%T')

    if @verb == 'ListRecords'
      self.list_records
    elsif @verb == 'ListSets'
      self.list_sets
    elsif @verb == 'GetRecord'
      if identifier.blank?
        raise("Requested GetRecord but did not provide an identifier parameter.")
      end
      self.get_single_record(identifier)
    end


  end

  def list_records
    @records =
        RSolr.connect(url: "#{ActiveFedora.config.credentials[:url].gsub('/fedora/rest', '/solr/cloneprod')}")
            .get('select', params: {
                'q' => 'is_public_ssi:true AND active_fedora_model_ssi:GenericFile',
                #'fl' => 'id,timestamp,xml',
                'rows' => ROWS,
                'start' => @start
            })['response']['docs'].map do |d|
          ListRecord.new(
              d['id'],
              d['timestamp'],
              #PBCore.new(d['xml'])
              GenericFile.find(d['id'],
              d['collection_name_ssim'])
          )
        end

    # Not ideal: they'll need to go past the end.
    @next_resumption_token = @start + ROWS unless @records.empty? || @records.length < 100

    respond_to do |format|
      format.xml do
        render :template => "oai/list_records"
      end
    end
  end

  def list_sets
    @records =
        RSolr.connect(url: "#{ActiveFedora.config.credentials[:url].gsub('/fedora/rest', '/solr/cloneprod')}")
            .get('select', params: {
                'q' => 'is_public_ssi:true AND active_fedora_model_ssi:Collection',
                #'fl' => 'id,timestamp,xml',
                'rows' => ROWS,
                'start' => @start
            })['response']['docs'].map do |d|
          SetRecord.new(
              d['id'],
              d['timestamp'],
              d['title_tesim'][0],
              d['description_tesim'].join('<br /><br />')
          )
        end

    # Not ideal: they'll need to go past the end.
    @next_resumption_token = @start + ROWS unless @records.empty? || @records.length < 100

    respond_to do |format|
      format.xml do
        render :template => "oai/list_sets"
      end
    end
  end

  def get_single_record pid
    @records =
        RSolr.connect(url: "#{ActiveFedora.config.credentials[:url].gsub('/fedora/rest', '/solr/cloneprod')}")
            .get('select', params: {
                'q' => 'is_public_ssi:true AND active_fedora_model_ssi:GenericFile AND id:' + pid,
                #'fl' => 'id,timestamp,xml',
                'rows' => ROWS,
                'start' => @start
            })['response']['docs'].map do |d|
          ListRecord.new(
              d['id'],
              d['timestamp'],
              #PBCore.new(d['xml'])
              GenericFile.find(d['id'],
              d['collection_name_ssim'])
          )
        end

    # Not ideal: they'll need to go past the end.
    @next_resumption_token = @start + ROWS unless @records.empty? || @records.length < 100

    respond_to do |format|
      format.xml do
        render :template => "oai/get_record"
      end
    end
  end
end