class SingleTextInput < SingleTextBaseInput
  include WithHelpIcon

  def input_type
    'no_repeat_field_value'.freeze
  end
end