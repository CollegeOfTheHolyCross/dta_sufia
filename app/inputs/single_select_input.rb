class SingleSelectInput < MultiBaseInput
  def input_type
    'no_repeat_field_value'.freeze
  end

  def input(wrapper_options)
    @rendered_first_element = false
    input_html_classes.unshift("string")
    input_html_options[:name] ||= "#{object_name}[#{attribute_name}]"

    outer_wrapper do
      buffer_each(collection) do |value, index|
        inner_wrapper do
          build_field(value, index)
        end
      end
    end
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

  private

  def select_options
    @select_options ||= begin
      collection = options.delete(:collection) || self.class.boolean_collection
      collection.respond_to?(:call) ? collection.call : collection.to_a
    end
  end

  def build_field(value, _index)
    html_options = input_html_options.dup

    if @rendered_first_element
      html_options[:id] = nil
      html_options[:required] = nil
    else
      html_options[:id] ||= input_dom_id
    end
    html_options[:class] ||= []
    html_options[:class] += ["#{input_dom_id} form-control multi-text-field"]
    html_options[:'aria-labelledby'] = label_id
    html_options.delete(:multiple)
    @rendered_first_element = true

    html_options.merge!(options.slice(:include_blank))
    template.select_tag(attribute_name, template.options_for_select(select_options, value), html_options)
  end
end