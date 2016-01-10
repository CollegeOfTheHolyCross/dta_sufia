module SufiaHelper
  include ::BlacklightHelper
  include Sufia::BlacklightOverride
  include Sufia::SufiaHelperBehavior

  # You can configure blacklight to use this as the thumbnail
  # example:
  #   config.index.thumbnail_method = :sufia_thumbnail_tag
  def sufia_thumbnail_tag(document, options)
    # collection
    if document.collection?
      if document["hasCollectionMember_ssim"].present?
        path = sufia.download_path document["hasCollectionMember_ssim"].first, file: 'thumbnail'
        options[:alt] = ""
        image_tag path, options
      else
        #content_tag(:span, "", class: "glyphicon glyphicon-th collection-icon-search")
        options[:alt] = ""
        image_tag "site_images/collection-icon.svg", options
      end

      #content_tag(:span, "", class: "glyphicon glyphicon-th collection-icon-search")

      # file
    else
      path =
          if document.image? || document.pdf? || document.video? || document.office_document?
            sufia.download_path document, file: 'thumbnail'
          elsif document.audio?
            "audio.png"
          else
            "default.png"
          end
      options[:alt] = ""
      image_tag path, options
    end
  end
end
