class SelectWithModalNoBlankInput < SelectWithModalHelpInput
  def buffer_each(collection)
    collection.each_with_object('').with_index do |(value, buffer), index|
      buffer << yield(value, index) unless @rendered_first_element && value.blank?
    end
  end

end