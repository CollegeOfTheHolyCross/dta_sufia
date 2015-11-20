

Blacklight.onLoad(function() {
        $(".regular_dta_duplicate_field").click(function(event) {
            //cloned_element = $(event.target).parent().parent().parent().parent().clone(true, true)
            cloned_element = $(event.target).parent().parent().parent().clone(true, true)
            cloned_element.find("input").val("");
            //$(event.target).parent().parent().parent().parent().after(cloned_element);
            $(event.target).parent().parent().parent().after(cloned_element);
        });

        $(".regular_dta_delete_field").click(function(event) {
            //parent().parent().children().length
            local_field_name = $(event.target).parent().prev().prev().attr('name');

            //Current hack for lookup fields... may need more when I add hidden fields...
            if(local_field_name == undefined) {
                local_field_name = $(event.target).parent().prev().prev().prev().attr('name');
            }
            if ($('input[name*="' + local_field_name + '"]').length == 1) {
                //$(event.target).parent().parent().parent().parent().find("input").val("");
                $(event.target).parent().parent().parent().find("input").val("");
            } else if($('select[name*="' + local_field_name + '"]').length == 1) {
                //$(event.target).parent().parent().parent().parent().find("select").val("");
                $(event.target).parent().parent().parent().find("select").val("");
            } else {
                //$(event.target).parent().parent().parent().parent().remove();
                $(event.target).parent().parent().parent().remove();
            }
        });

    });

