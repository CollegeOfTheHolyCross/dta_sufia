Blacklight.onLoad(function() {


    // there are two levels of vocabulary auto complete.
    // currently we have this externally hosted vocabulary
    // for geonames.  I'm not going to make these any easier
    // to implement for an external url (it's all hard coded)
    // because I'm guessing we'll get away from the hard coding
    var cities_autocomplete_opts = {
        source: function( request, response ) {
            $.ajax( {
                url: "http://ws.geonames.org/searchJSON",
                dataType: "jsonp",
                data: {
                    featureClass: "P",
                    style: "full",
                    maxRows: 12,
                    name_startsWith: request.term,
                    username: 'boston_library' //FIXME still
                },
                success: function( data ) {        response( $.map( data.geonames, function( item ) {
                    return {
                        label: item.name + (item.adminName1 ? ", " + item.adminName1 : "") + ", " + item.countryName,
                        value: item.name + (item.adminName1 ? ", " + item.adminName1 : "") + ", " + item.countryName
                    };
                }));
                },
            });
        },
        minLength: 2
    };

    //$("input.generic_file_based_near").autocomplete(get_autocomplete_opts("location"));


    // attach an auto complete based on the field
    /*function setup_autocomplete(e, cloneElem) {
        var $cloneElem = $(cloneElem);
        // FIXME this code (comparing the id) depends on a bug. Each input has an id and the id is
        // duplicated when you press the plus button. This is not valid html.
        if ($cloneElem.attr("id") == 'generic_file_based_near') {
            $cloneElem.autocomplete(cities_autocomplete_opts);
        } else if ( (index = $.inArray($cloneElem.attr("id"), autocomplete_vocab.field_name)) != -1 ) {
            $cloneElem.autocomplete(get_autocomplete_opts(autocomplete_vocab.url_var[index]));
        }
    }

    $('.multi_value.form-group').manage_fields({add: setup_autocomplete});
    */

});