class SingleBaseInput < SimpleForm::Inputs::StringInput
  def input(wrapper_options = nil)
    unless string?
      input_html_classes.unshift("string")
      input_html_options[:type] ||= input_type if html5?
    end

    outer_wrapper do
      inner_wrapper do
        build_field(wrapper_options)
      end
    end
  end

  protected

  def buffer_each(collection)
    collection.each_with_object('').with_index do |(value, buffer), index|
      buffer << yield(value, index)
    end
  end

  def outer_wrapper
    "    <ul class=\"listing\">\n        #{yield}\n      </ul>\n"
  end


  def inner_wrapper
    <<-HTML
          <li class="field-wrapper">
             <div class="input-group col-sm-12">
              #{yield}
              </div>
          </li>
    HTML
  end

  def build_field(wrapper_options)
    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    @builder.text_field(attribute_name, merged_input_options)
  end
end