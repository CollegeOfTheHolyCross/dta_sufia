class SingleTextBaseInput < SimpleForm::Inputs::TextInput
  def input(wrapper_options = nil)

    outer_wrapper do
      inner_wrapper do
        build_field(wrapper_options)
      end
    end
  end

  protected

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

    @builder.text_area(attribute_name, merged_input_options)
  end
end