Sufia.config do |config|
  config.lock_retry_count = 600 # Up to 2 minutes of trying at intervals up to 200ms
  config.lock_time_to_live = 12_000 # milliseconds
  config.lock_retry_delay = 200 # milliseconds

  config.fits_to_desc_mapping = {
    file_title: :title,
    file_author: :creator
  }

  config.max_days_between_audits = 7

  config.max_notifications_for_dashboard = 5

  config.cc_licenses = {
      'Contact host institution for more information' => 'Contact host institution for more information',
    'No known restrictions on use' => 'No known restrictions on use',
    'All rights reserved' => 'All rights reserved'

  }

  config.cc_licenses_reverse = Hash[*config.cc_licenses.to_a.flatten.reverse]

  config.spatial_dropdown = [
      ['Cities', 'P'],
      ['Building', 'S'],
      ['State/Country/Region', 'A'],
      ['Geographic Territory', 'T'],
      ['Continent/Area', 'L']
  ]

=begin
  config.resource_types = {
    "Article" => "Article",
    "Audio" => "Audio",
    "Book" => "Book",
    "Capstone Project" => "Capstone Project",
    "Conference Proceeding" => "Conference Proceeding",
    "Dataset" => "Dataset",
    "Dissertation" => "Dissertation",
    "Image" => "Image",
    "Journal" => "Journal",
    "Map or Cartographic Material" => "Map or Cartographic Material",
    "Masters Thesis" => "Masters Thesis",
    "Part of Book" => "Part of Book",
    "Poster" => "Poster",
    "Presentation" => "Presentation",
    "Project" => "Project",
    "Report" => "Report",
    "Research Paper" => "Research Paper",
    "Software or Program Code" => "Software or Program Code",
    "Video" => "Video",
    "Other" => "Other"
  }

  config.resource_types_to_schema = {
    "Article" => "http://schema.org/Article",
    "Audio" => "http://schema.org/AudioObject",
    "Book" => "http://schema.org/Book",
    "Capstone Project" => "http://schema.org/CreativeWork",
    "Conference Proceeding" => "http://schema.org/ScholarlyArticle",
    "Dataset" => "http://schema.org/Dataset",
    "Dissertation" => "http://schema.org/ScholarlyArticle",
    "Image" => "http://schema.org/ImageObject",
    "Journal" => "http://schema.org/CreativeWork",
    "Map or Cartographic Material" => "http://schema.org/Map",
    "Masters Thesis" => "http://schema.org/ScholarlyArticle",
    "Part of Book" => "http://schema.org/Book",
    "Poster" => "http://schema.org/CreativeWork",
    "Presentation" => "http://schema.org/CreativeWork",
    "Project" => "http://schema.org/CreativeWork",
    "Report" => "http://schema.org/CreativeWork",
    "Research Paper" => "http://schema.org/ScholarlyArticle",
    "Software or Program Code" => "http://schema.org/Code",
    "Video" => "http://schema.org/VideoObject",
    "Other" => "http://schema.org/CreativeWork"
  }
=end



  config.resource_types = {
      "Artifact" => "Artifact",
      "Audio" => "Audio",
      "Cartographic" => "Cartographic",
      "Collection" => "Collection",
      "Dataset" => "Dataset",
      "Digital [indicates born­digital]" => "Digital [indicates born­digital]",
      "Manuscript" => "Manuscript",
      "Mixed material" => "Mixed material",
      "Moving image" => "Moving image",
      "Multimedia" => "Multimedia",
      "Notated music" => "Notated music",
      "Still Image" => "Still Image",
      "Tactile" => "Tactile",
      "Text" => "Text",
      "Unspecified" => "Unspecified"
  }

  config.resource_types_to_schema = {
      "Artifact" => "http://id.loc.gov/vocabulary/resourceTypes/art",
      "Audio" => "http://id.loc.gov/vocabulary/resourceTypes/aud",
      "Cartographic" => "http://id.loc.gov/vocabulary/resourceTypes/car",
      "Collection" => "http://id.loc.gov/vocabulary/resourceTypes/col",
      "Dataset" => "http://id.loc.gov/vocabulary/resourceTypes/dat",
      "Digital [indicates born­digital]" => "http://id.loc.gov/vocabulary/resourceTypes/dig",
      "Manuscript" => "http://id.loc.gov/vocabulary/resourceTypes/man",
      "Mixed material" => "http://id.loc.gov/vocabulary/resourceTypes/mix",
      "Moving image" => "http://id.loc.gov/vocabulary/resourceTypes/mov",
      "Multimedia" => "http://id.loc.gov/vocabulary/resourceTypes/mul",
      "Notated music" => "http://id.loc.gov/vocabulary/resourceTypes/not",
      "Still Image" => "http://id.loc.gov/vocabulary/resourceTypes/img",
      "Tactile" => "http://id.loc.gov/vocabulary/resourceTypes/tac",
      "Text" => "http://id.loc.gov/vocabulary/resourceTypes/txt",
      "Unspecified" => "http://id.loc.gov/vocabulary/resourceTypes/unk"
  }

  config.genre_list = {
      "Advertisements" => "Advertisements",
      "Albums" => "Albums",
      "Art" => "Art",
      "Articles" => "Articles",
      "Awards" => "Awards",
      "Autobiographies" => "Autobiographies",
      "Bibliographies" => "Bibliographies",
      "Birth Certificates" => "Birth Certificates",
      "Books" => "Books",
      "Calendars" => "Calendars",
      "Cards" => "Cards",
      "Catalogs" => "Catalogs",
      "Charts" => "Charts",
      "Clippings" => "Clippings",
      "Correspondence" => "Correspondence",
      "Dictionaries" => "Dictionaries",
      "Diaries" => "Diaries",
      "Directories" => "Directories",
      "Documents" => "Documents",
      "Drama" => "Drama",
      "Drawings" => "Drawings",

      "Ephemera" => "Ephemera",
      "Encyclopedias" => "Encyclopedias",
      "Erotica" => "Erotica",
      "Essays" => "Essays",
      "Fiction" => "Fiction",
      "Finding Aids" => "Finding Aids",
      "Government Publications" => "Government Publications",
      "Government Records" => "Government Records",
      "Handbooks" => "Handbooks",
      "Leaflets" => "Leaflets",
      "Lecture Notes" => "Lecture Notes",
      "Legal Cases" => "Legal Cases",
      "Manuscripts" => "Manuscripts",
      "Maps" => "Maps",
      "Motion Pictures" => "Motion Pictures",
      "Musical Notation" => "Musical Notation",
      "Newsletters" => "Newsletters",
      "Newspapers" => "Newspapers",
      "Oral Histories" => "Oral Histories",
      "Paintings" => "Paintings",

      "Pamphlets" => "Pamphlets",
      "Periodicals" => "Periodicals",
      "Petitions" => "Petitions",
      "Photographs" => "Photographs",
      "Physical Objects" => "Physical Objects",
      "Poetry" => "Poetry",
      "Posters" => "Posters",
      "Press Releases" => "Press Releases",
      "Prints" => "Prints",
      "Programs" => "Programs",
      "Records" => "Records",
      "Reviews" => "Reviews",
      "Sound Recordings" => "Sound Recordings",
      "Speeches" => "Speeches",
      "Surveys" => "Surveys",
      "Theses" => "Theses",
      "Transcriptions" => "Transcriptions",
      "Websites" => "Websites",
      "Yearbooks" => "Yearbooks"
  }

  config.genre_to_loc = {
      "Albums" => "http://id.loc.gov/vocabulary/graphicMaterials/tgm000229",
      "Books" => "http://id.loc.gov/vocabulary/graphicMaterials/tgm001221",
      "Cards" => "http://id.loc.gov/vocabulary/graphicMaterials/tgm001686",
      "Correspondence" => "http://id.loc.gov/vocabulary/graphicMaterials/tgm002590",
      "Documents" => "http://id.loc.gov/vocabulary/graphicMaterials/tgm003185",
      "Drawings" => "http://id.loc.gov/vocabulary/graphicMaterials/tgm003279",
      "Ephemera" => "http://id.loc.gov/vocabulary/graphicMaterials/tgm003634",
      "Manuscripts" => "http://id.loc.gov/vocabulary/graphicMaterials/tgm012286",
      "Maps" => "http://id.loc.gov/vocabulary/graphicMaterials/tgm006261",
      "Motion Pictures" => "http://id.loc.gov/vocabulary/graphicMaterials/tgm006804",
      "Music" => "http://id.loc.gov/vocabulary/graphicMaterials/tgm006906",
      "Musical Notation" => "http://id.loc.gov/vocabulary/graphicMaterials/tgm006926",
      "Newspapers" => "http://id.loc.gov/vocabulary/graphicMaterials/tgm007068",
      "Paintings" => "http://id.loc.gov/vocabulary/graphicMaterials/tgm007393",
      "Periodicals" => "http://id.loc.gov/vocabulary/graphicMaterials/tgm007641",
      "Photographs" => "http://id.loc.gov/vocabulary/graphicMaterials/tgm007721",
      "Posters" => "http://id.loc.gov/vocabulary/graphicMaterials/tgm008104",
      "Prints" => "http://id.loc.gov/vocabulary/graphicMaterials/tgm008237",
      "Sound Recordings" => "http://id.loc.gov/vocabulary/graphicMaterials/tgm009874"
  }

  config.permission_levels = {
    "Choose Access" => "none",
    "View/Download" => "read",
    "Edit" => "edit"
  }

  config.owner_permission_levels = {
    "Edit" => "edit"
  }
  
  config.language_list = {
  	"English" => "English",
  	"French" => "French",
  	"Spanish" => "Spanish",
  	"German" => "German"
  }

  config.flagged_list = {
      "No explicit content" => "No explicit content",
      "Explicit content in thumbnail" => "Explicit content in thumbnail",
      "Explicit content, but not in thumbnail" => "Explicit content, but not in thumbnail"
  }

  config.queue = Sufia::Resque::Queue

  config.geonames_username = 'boston_library'

  # Enable displaying usage statistics in the UI
  # Defaults to FALSE
  # Requires a Google Analytics id and OAuth2 keyfile.  See README for more info
  config.analytics = false

  # Specify a Google Analytics tracking ID to gather usage statistics
  # config.google_analytics_id = 'UA-99999999-1'

  # Specify a date you wish to start collecting Google Analytic statistics for.
  # config.analytic_start_date = DateTime.new(2014,9,10)

  # Where to store tempfiles, leave blank for the system temp directory (e.g. /tmp)
  # config.temp_file_base = '/home/developer1'

  # Specify the form of hostpath to be used in Endnote exports
  # config.persistent_hostpath = 'http://localhost/files/'

  # If you have ffmpeg installed and want to transcode audio and video uncomment this line
  # config.enable_ffmpeg = true

  # Sufia uses NOIDs for files and collections instead of Fedora UUIDs
  # where NOID = 10-character string and UUID = 32-character string w/ hyphens
  # config.enable_noids = true

  # Specify a different template for your repository's NOID IDs
  # config.noid_template = ".reeddeeddk"

  # Store identifier minter's state in a file for later replayability
  # config.minter_statefile = '/tmp/minter-state'

  # Process for translating Fedora URIs to identifiers and vice versa
  # config.translate_uri_to_id = ActiveFedora::Noid.config.translate_uri_to_id
  # config.translate_id_to_uri = ActiveFedora::Noid.config.translate_id_to_uri

  # Specify the prefix for Redis keys:
  # config.redis_namespace = "sufia"

  # Specify the path to the file characterization tool:
  config.fits_path = ENV["FITS_PATH"]

  config.upload_to_collection = true

  # Specify how many seconds back from the current time that we should show by default of the user's activity on the user's dashboard
  # config.activity_to_show_default_seconds_since_now = 24*60*60

  # Sufia can integrate with Zotero's Arkivo service for automatic deposit
  # of Zotero-managed research items.
  # config.arkivo_api = false

  # Specify a date you wish to start collecting Google Analytic statistics for.
  # Leaving it blank will set the start date to when ever the file was uploaded by
  # NOTE: if you have always sent analytics to GA for downloads and page views leave this commented out
  # config.analytic_start_date = DateTime.new(2014,9,10)

  # If browse-everything has been configured, load the configs.  Otherwise, set to nil.
  begin
    if defined? BrowseEverything
      config.browse_everything = BrowseEverything.config
    else
      Rails.logger.warn "BrowseEverything is not installed"
    end
  rescue Errno::ENOENT
    config.browse_everything = nil
  end
end

Date::DATE_FORMATS[:standard] = "%m/%d/%Y"

#Hydra::Derivatives.libreoffice_path = ENV["LIBREOFFICE_PATH"]
#Hydra::Derivatives.kdu_compress_path = ENV["KDU_PATH"]
