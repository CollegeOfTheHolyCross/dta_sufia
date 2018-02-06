# -*- coding: utf-8 -*-
module GenericFileHelper
  def display_title(gf)
    gf.to_s
  end

  def present_terms(presenter, terms = :all, &block)
    terms = presenter.terms if terms == :all
    Sufia::PresenterRenderer.new(presenter, self).fields(terms, &block)
  end

  def render_download_icon(title = nil)
    if @generic_file.hosted_elsewhere == "1"
      if title.nil?
        link_to download_image_tag, @generic_file.is_shown_at, target: "_blank", title: "Link to this resource", id: "file_download"
      else
        label = download_image_tag(title)
        link_to label, @generic_file.is_shown_at, target: "_blank", title: title, id: "file_download"
      end
    else
      if title.nil?
        if @document.present? && @document['mime_type_tesim'].present? && (@document['mime_type_tesim'].include?('image/tiff') || @document['mime_type_tesim'].include?('image/jpeg') || @document['mime_type_tesim'].include?('image/jpg')  || @document['mime_type_tesim'].include?('image/png'))
          link_to download_image_tag, '#', target: "_blank", title: "View in image viewer", id: "img_viewer_link", data: { label: @generic_file.id }, :rel => 'nofollow'
        else
          link_to download_image_tag, sufia.download_path(@generic_file), target: "_blank", title: "Download the document", id: "file_download", data: { label: @generic_file.id }
        end
      else
        if @document.present? && @document['mime_type_tesim'].present? && (@document['mime_type_tesim'].include?('image/tiff') || @document['mime_type_tesim'].include?('image/jpeg') || @document['mime_type_tesim'].include?('image/jpg')  || @document['mime_type_tesim'].include?('image/png'))
          label = download_image_tag(title)
          link_to label, '#', target: "_blank", title: "View in image viewer", id: "img_viewer_link", data: { label: @generic_file.id }, :rel => 'nofollow'
        else
          label = download_image_tag(title)
          link_to label, sufia.download_path(@generic_file), target: "_blank", title: title, id: "file_download", data: { label: @generic_file.id }
        end

      end
    end

  end

  def render_download_link(text = nil)
    label = text || 'Download'
    link_to label, sufia.download_path(@generic_file), id: "file_download", target: "_new", data: { label: @generic_file.id }
  end

  def render_collection_list(gf)
      ("Is part of: " + gf.collections.map { |c| link_to(c.title, collections.collection_path(c)) }.join(", ")).html_safe unless gf.collections.empty?
  end

  def display_multiple(value)
    auto_link(value.join(" <br /><br /> "))
  end

  private

  def download_image_tag(title = nil)
    content_tag :figure do
      if title.nil?
        if @generic_file.resource_type.include?('Audio') || @generic_file.genre.include?('Sound Recordings')
          concat image_tag "shared/dta_audio_icon.jpg", alt: "No preview available", class: "img-responsive"
        else
          concat image_tag "default.png", alt: "No preview available", class: "img-responsive"
        end

      else
        concat image_tag sufia.download_path(@generic_file, file: 'thumbnail'), class: "img-responsive", alt: "#{title} of #{@generic_file.title.first}"
      end
      concat content_tag :figcaption, "Download the full sized image"
    end
  end

  def render_visibility_badge
    if can? :edit, @generic_file
      render_visibility_link @generic_file
    else
      render_visibility_label @generic_file
    end
  end
end
