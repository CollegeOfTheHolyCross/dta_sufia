class LanguageStringInput < MultiStringInput

  def buffer_each(collection)
    collection.each_with_object('').with_index do |(value, buffer), index|
      if !@rendered_first_element && value.blank?
        buffer << yield('http://id.loc.gov/vocabulary/iso639-2/eng', index)
      else
        buffer << yield(value, index) unless @rendered_first_element && value.blank?
      end
    end
  end





end
