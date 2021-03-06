# encoding: utf-8
require 'zip'
require "net/http"
require "uri"

AUDIO_TYPES = ['mp3', 'wav', 'mp4']

class IngestBase
  def self.fetch(uri_str, limit = 10)
    # You should choose better exception.
    raise ArgumentError, 'HTTP redirect too deep' if limit == 0

    url = URI.parse(uri_str)
    req = Net::HTTP::Get.new(url.path, { 'User-Agent' => 'Mozilla/5.0 (etc...)' })
    response = Net::HTTP.start(url.host, url.port, :use_ssl => url.scheme == 'https') { |http| http.request(req) }
    case response
      when Net::HTTPSuccess     then response
      when Net::HTTPRedirection then fetch(response['location'], limit - 1)
      else
        response.error!
    end
  end

  def self.get_redirect(uri_str)
    # You should choose better exception.
    url = URI.parse(uri_str)
    req = Net::HTTP::Get.new(url.path, { 'User-Agent' => 'Mozilla/5.0 (etc...)' })
    response = Net::HTTP.start(url.host, url.port, :use_ssl => url.scheme == 'https') { |http| http.request(req) }
    case response
      when Net::HTTPRedirection then return response['location']
      else
        response.error!
    end
  end

  def self.insert_date(date_text)
    original_date = date_text.clone
    date_text = date_text.strip.gsub('-','/')
    date_text = '1977~' if date_text == 'circa 1977' || date_text == 'ca. 1977'
    date_text = '1985/1989' if date_text == 'between 1985 and 1989'
    date_text = '1980?/1989?' if date_text == '1980sca.' || date_text == 'ca. 1980s'
    date_text = '1974~' if date_text == 'circa 1974' || date_text == 'ca. 1974'
    date_text = '1980/1984' if date_text == '1980 / 1984'
    date_text = '1986~' if date_text == 'circa 1986'
    date_text = '1985~' if date_text == 'ca. 1985' || date_text == 'circa 1985'
    date = Date.edtf(date_text)

    if date.present?
      @generic_file.date_created = [date.edtf]
    elsif date_text.present?
      raise "Could not parse date for: " + original_date
    end
  end

  def self.insert_subject(subject_element, record_id)
    if subject_element.strip.downcase == 'group portraits'
      @generic_file.homosaurus_subject += ['http://id.loc.gov/authorities/subjects/sh85105182']
    elsif subject_element.strip.downcase == 'flowers (plants)'
      @generic_file.homosaurus_subject += ['http://id.loc.gov/authorities/subjects/sh85049332']
    elsif subject_element.strip.downcase == 'banjos'
      @generic_file.homosaurus_subject += ['http://id.loc.gov/authorities/subjects/sh85011545']
    elsif subject_element.strip.downcase == 'wedding dresses'
      #@generic_file.homosaurus_subject += ['wedding dresses']
    elsif subject_element.strip.downcase == 'costumes'
      @generic_file.homosaurus_subject += ['http://id.loc.gov/authorities/subjects/sh85033238']
    elsif subject_element.strip.downcase == 'meals'
      #@generic_file.homosaurus_subject += ['meals']
    elsif subject_element.strip.downcase == 'guitars'
      @generic_file.homosaurus_subject +=  ['http://id.loc.gov/authorities/subjects/sh85057803']
    elsif subject_element.strip.downcase == 'dressing rooms'
      @generic_file.homosaurus_subject +=  ['http://id.loc.gov/authorities/subjects/sh94005982']
    elsif subject_element.strip.downcase == 'beach grass'
      #skip
    elsif subject_element.strip.downcase == 'violins'
      @generic_file.homosaurus_subject += ['http://id.loc.gov/authorities/subjects/sh85143544']
    elsif subject_element.strip.downcase == 'steps'
      # This is stairs
      @generic_file.homosaurus_subject += ['http://id.loc.gov/authorities/subjects/sh85127267']
    else

      solr_response = Homosaurus.find_with_conditions("dta_homosaurus_lcase_prefLabel_ssi:#{solr_clean(subject_element.strip.downcase)}", rows: '25', fl: 'identifier_ssi, prefLabel_ssim, altLabel_ssim, narrower_ssim, broader_ssim, related_ssim' ) unless subject_element.strip.include?('(')
      if solr_response.present? and solr_response.count == 1
        @generic_file.homosaurus_subject += ['http://homosaurus.org/terms/' + solr_response.first['identifier_ssi']]
      elsif  solr_response.present? and solr_response.count > 1
        raise "Solr count mismatch for " + record_id
      else
        authority_check = Mei::Loc.new('subjects')
        authority_result = authority_check.search(subject_element.strip) #URI escaping doesn't work for Baseball fields?
        if authority_result.present?
          authority_result = authority_result.select{|hash| hash['label'].downcase == subject_element.strip.downcase }
          if  authority_result.present?
            @generic_file.homosaurus_subject += [authority_result.first["uri_link"].gsub('info:lc', 'http://id.loc.gov')]
          else
            raise "No homosaurus or LCSH match for " + record_id + " for subject value: " + subject_element.strip
          end
        end
      end
    end
  end

  def self.acquire_lock_for(lock_key, &block)
    lock_manager.lock(lock_key, &block)
  end

  def self.lock_manager
    @lock_manager ||= Sufia::LockManager.new(
        Sufia.config.lock_time_to_live,
        Sufia.config.lock_retry_count,
        Sufia.config.lock_retry_delay)
  end

  def self.solr_clean(term)
    return term.gsub('\\', '\\\\').gsub(':', '\\:').gsub(' ', '\ ')
  end
end