class SingleStringInput < SingleBaseInput
  include WithHelpIcon

  def input_type
    #'multi_value'.freeze
    'no_repeat_field_value'.freeze
  end
end