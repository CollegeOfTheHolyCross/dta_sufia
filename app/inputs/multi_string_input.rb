class MultiStringInput < MultiBaseInput
  include WithHelpIcon


  # Overriding this so that the class is correct and the javascript for multivalue will work on this.
  def input_type
    #'multi_value'.freeze
    'repeat_field_value'.freeze
  end




end
