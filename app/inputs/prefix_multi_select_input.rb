class PrefixMultiSelectInput < MultiSelectInput


  def inner_wrapper
    <<-HTML
          <li class="field-wrapper">
             <div class="input-group col-sm-12">
              <span class="input-group-addon">http://homosaurus.org/terms/</span>
              #{yield}

              <span class="input-group-btn regular_dta_duplicate_span">
                <button class="btn btn-success regular_dta_duplicate_field" type="button">+</button>
              </span>
                    <span class="input-group-btn">
                      <button class="btn btn-danger regular_dta_delete_field" type="button">-</button>
                    </span>
              </div>
          </li>
    HTML
  end

end