class CollectionArrayInput < SimpleForm::Inputs::CollectionSelectInput

  def input(wrapper_options = nil)
    return collection_field(nil,wrapper_options).html_safe if attributes_array.empty?
    attributes_array.map do |array_el|
      collection_field(array_el,wrapper_options)
    end.join.html_safe

  end

  def attributes_array
    @attributes_array ||= Array(object.public_send(attribute_name))
  end

  def collection_field(array_el, wrapper_options)
    label_method, value_method = detect_collection_methods

    merged_input_options = merge_wrapper_options(input_html_options.merge(name: "#{object_name}[#{attribute_name}][]"), wrapper_options)
    #selected: array_el,

    @builder.collection_select(
        attribute_name, collection, value_method, label_method,
        input_options, merged_input_options
    )

  end



end
