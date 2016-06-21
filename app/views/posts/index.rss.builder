#encoding: UTF-8

xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "Digital Transgender Archive News"
    xml.author "Digital Transgender Archive"
    xml.description "Latest news and updates from the DTA."
    xml.link "https://www.digitaltransgenderarchive.net/news"
    xml.language "en"

    for article in @posts
      xml.item do
        if article.title
          xml.title article.title
        else
          xml.title ""
        end
        xml.author ""
        xml.pubDate article.created.to_s(:rfc822)
        xml.link "https://www.digitaltransgenderarchive.net/news/#{article.friendly_id}"
        xml.guid article.friendly_id

        text = article.content
        # if you like, do something with your content text here e.g. insert image tags.
        # Optional. I'm doing this on my website.
        if article.thumbnail.present?
          image_url = article.thumbnail
          image_caption = ''
          image_align = "left"
          image_tag = "
                <p><img src='" + image_url +  "' alt='" + image_caption + "' title='" + image_caption + "' align='" + image_align  + "' /></p>
              "
          text = text.sub('{image}', image_tag)
        end
        xml.description "<p>" + text + "</p>"
      end
    end
  end
end
