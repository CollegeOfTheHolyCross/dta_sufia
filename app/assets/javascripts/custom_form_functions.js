

Blacklight.onLoad(function() {
    function get_autocomplete_opts(field) {
        var autocomplete_opts = {
            minLength: 2,
            source: function( request, response ) {
                $.getJSON( "/authorities/generic_files/" + field, {
                    q: request.term
                }, response );
            },
            focus: function() {
                // prevent value inserted on focus
                return false;
            },
            complete: function(event) {
                $('.ui-autocomplete-loading').removeClass("ui-autocomplete-loading");
            }
        };
        return autocomplete_opts;
    }


    var autocomplete_vocab = new Object();

    autocomplete_vocab.url_var = ['other_subject', 'language', 'creator', 'contributor', 'rights_free_text', 'publisher'];   // the url variable to pass to determine the vocab to attach to
    autocomplete_vocab.field_name = new Array(); // the form name to attach the event for autocomplete

    // loop over the autocomplete fields and attach the
    // events for autocomplete and create other array values for autocomplete
    for (var i=0; i < autocomplete_vocab.url_var.length; i++) {
        autocomplete_vocab.field_name.push('generic_file_' + autocomplete_vocab.url_var[i]);
        // autocompletes
        $("input." + autocomplete_vocab.field_name[i])
            // don't navigate away from the field on tab when selecting an item
            .bind( "keydown", function( event ) {
                if ( event.keyCode === $.ui.keyCode.TAB &&
                    $( this ).data( "autocomplete" ).menu.active ) {
                    event.preventDefault();
                }
            })
            .autocomplete( get_autocomplete_opts(autocomplete_vocab.url_var[i]) );
    }

    function duplicate_field_click(event) {
        original_element = $(event.target).parent().parent().parent().children().children();
        original_id = original_element.attr("id");

        if(original_id == 'generic_file_language' || original_id == 'generic_file_other_subject' || original_id == 'generic_file_creator' || original_id == 'generic_file_contributor' || original_id == 'generic_file_rights_free_text'  || original_id == 'generic_file_publisher' ) {
            cloned_element = $(event.target).parent().parent().parent().clone()
        } else {
            cloned_element = $(event.target).parent().parent().parent().clone(true, true);
        }



        cloned_element.find("input").val("");
        cloned_element.find("textarea").val("");
        cloned_element.find("select").val("");

        $(event.target).parent().parent().parent().after(cloned_element);


        //alert(cloned_element.children().children().attr("id"));

        /*            id = cloned_element.children().children().attr("id");
         if(id == 'generic_file_language') {
         cloned_field = cloned_element.children().children();
         index = $.inArray(id, autocomplete_vocab.field_name);
         alert('index is: ' + index);
         if(index != -1)
         {
         $(cloned_field).autocomplete(get_autocomplete_opts(autocomplete_vocab.url_var[index]));
         }

         }*/

        //$(event.target).parent().parent().parent().parent().after(cloned_element);




        if(original_id == 'generic_file_language' || original_id == 'generic_file_other_subject' || original_id == 'generic_file_creator' || original_id == 'generic_file_contributor'  || original_id == 'generic_file_rights_free_text'  || original_id == 'generic_file_publisher' ) {
            added_element = $(event.target).parent().parent().parent().next().children().children();
            added_add_button = $(event.target).parent().parent().parent().next().children().children('.regular_dta_duplicate_span').children('.regular_dta_duplicate_field');
            remove_add_button = $(event.target).parent().parent().parent().next().children().children('.regular_dta_delete_span').children('.regular_dta_delete_field');
            //added_id = added_element.attr("id");
            if(original_id == 'generic_file_language') {
                $(added_element).autocomplete(get_autocomplete_opts('language'));
            } else if(original_id == 'generic_file_other_subject') {
                $(added_element).autocomplete(get_autocomplete_opts('other_subject'));
            } else if(original_id == 'generic_file_creator') {
                $(added_element).autocomplete(get_autocomplete_opts('creator'));
            } else if(original_id == 'generic_file_contributor') {
                $(added_element).autocomplete(get_autocomplete_opts('contributor'));
            } else if(original_id == 'generic_file_rights_free_text') {
                $(added_element).autocomplete(get_autocomplete_opts('rights_free_text'));
            } else if(original_id == 'generic_file_publisher') {
                $(added_element).autocomplete(get_autocomplete_opts('publisher'));
            }

            added_add_button.click(duplicate_field_click);
            remove_add_button.click(delete_field_click);
        }
        //alert($(event.target).parent().parent().parent().next().children().children().attr("id"));

        /*            alert($(cloned_element).children()[0].attr("id"));
         if(cloned_element.attr("id") == 'generic_file_language')
         {
         alert('hi');
         }*/
    }

    function delete_field_click(event) {
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
    }

        $(".regular_dta_duplicate_field").click(duplicate_field_click);

        $(".regular_dta_delete_field").click(delete_field_click);

    });

