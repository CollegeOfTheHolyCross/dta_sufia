class LcshSubjectWithHelpInput < MultiValueInput
  include WithHelpIcon

  def inner_wrapper
    <<-HTML
          <li class="field-wrapper">
            #{yield}
            <button style="width:auto;" type="button" class="btn btn-default" data-toggle="modal" data-target="#exampleModal">Lookup</button>
          </li>
    HTML
  end

  def buffer_each(collection)
    collection.each_with_object('').with_index do |(value, buffer), index|
      buffer << yield(value, index) if value.match(/http:\/\/id.loc.gov\/authorities\/subjects\//) || value.blank?
    end
  end

  # Overriding this so that the class is correct and the javascript for multivalue will work on this.
  def input_type
    'multi_value'.freeze
  end
end
