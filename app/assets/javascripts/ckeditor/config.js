/*
 Copyright (c) 2003-2011, CKSource - Frederico Knabben. All rights reserved.
 For licensing, see LICENSE.html or http://ckeditor.com/license
 */



CKEDITOR.editorConfig = function( config )
{
    CKEDITOR.stylesSet.add( 'my_styles', [
        // Block-level styles.
        { name: 'Paragraph',		element: 'p' },
        { name: 'Bold Big Title',		element: 'h3' },
        { name: 'Bold SubTitle',		element: 'h4' },
        { name: 'Italic SubTitle',		element: 'h4', attributes: { 'class': 'pages_italic' } },

        { name: 'Preformatted Text',element: 'pre' },
        { name: 'Address',			element: 'address' },

        { name: 'Indented No Icon List',	element: 'ul',	attributes: { 'class': 'indent' } },

        { name: 'Marker',			element: 'span', attributes: { 'class': 'marker' } },

        { name: 'Big',				element: 'big' },
        { name: 'Small',			element: 'small' },
        { name: 'Typewriter',		element: 'tt' },

        { name: 'Computer Code',	element: 'code' },
        { name: 'Keyboard Phrase',	element: 'kbd' },
        { name: 'Sample Text',		element: 'samp' },
        { name: 'Variable',			element: 'var' },

        { name: 'Deleted Text',		element: 'del' },
        { name: 'Inserted Text',	element: 'ins' },

        { name: 'Cited Work',		element: 'cite' },
        { name: 'Inline Quotation',	element: 'q' },

        { name: 'Language: RTL',	element: 'span', attributes: { 'dir': 'rtl' } },
        { name: 'Language: LTR',	element: 'span', attributes: { 'dir': 'ltr' } },

    ]);

    config.stylesSet = 'my_styles';
    config.bodyClass = 'static_holder_content';
    //config.contentsCss = ['/assets/sufia.css', '/assets/dta/dta.css', '/assets/sufia_styles.css', '/assets/dta/about.css'] ;

    config.contentsCss = gon.compiled_application_css

    config.image_previewText = 'NOTE: This will not show in your page. This text is being used to ' +
        'demonstrate how text will look around your particular image. Essentially this just shows what content will look like ' +
        'near your image depending on your settings in this small preview window. It is only meant as a guide and, once again, ' +
        'will not appear once you have clicked on the "OK" button to have selected your image. So just ignore this beyond placement settings.';
    //config.contentsCss = '<%= link_to "application", :media => "all" %>'

    // Define changes to default configuration here. For example:
    // config.language = 'fr';
    // config.uiColor = '#AADC6E';

    /* Filebrowser routes */
    // The location of an external file browser, that should be launched when "Browse Server" button is pressed.
    config.filebrowserBrowseUrl = "/ckeditor/attachment_files";

    // The location of an external file browser, that should be launched when "Browse Server" button is pressed in the Flash dialog.
    config.filebrowserFlashBrowseUrl = "/ckeditor/attachment_files";

    // The location of a script that handles file uploads in the Flash dialog.
    config.filebrowserFlashUploadUrl = "/ckeditor/attachment_files";

    // The location of an external file browser, that should be launched when "Browse Server" button is pressed in the Link tab of Image dialog.
    config.filebrowserImageBrowseLinkUrl = "/ckeditor/pictures";

    // The location of an external file browser, that should be launched when "Browse Server" button is pressed in the Image dialog.
    config.filebrowserImageBrowseUrl = "/ckeditor/pictures";

    // The location of a script that handles file uploads in the Image dialog.
    config.filebrowserImageUploadUrl = "/ckeditor/pictures";

    // The location of a script that handles file uploads.
    config.filebrowserUploadUrl = "/ckeditor/attachment_files";

    config.allowedContent = true;

    // Toolbar groups configuration.
    config.toolbar = [
        { name: 'document', groups: [ 'mode', 'document', 'doctools' ], items: [ 'Source'] },
        { name: 'clipboard', groups: [ 'clipboard', 'undo' ], items: [ 'Cut', 'Copy', 'Paste', 'PasteText', 'PasteFromWord', '-', 'Undo', 'Redo' ] },
        // { name: 'editing', groups: [ 'find', 'selection', 'spellchecker' ], items: [ 'Find', 'Replace', '-', 'SelectAll', '-', 'Scayt' ] },
        // { name: 'forms', items: [ 'Form', 'Checkbox', 'Radio', 'TextField', 'Textarea', 'Select', 'Button', 'ImageButton', 'HiddenField' ] },
        { name: 'links', items: [ 'Link', 'Unlink', 'Anchor' ] },
        { name: 'insert', items: [ 'Image', 'Flash', 'Table', 'HorizontalRule', 'SpecialChar' ] },
        { name: 'paragraph', groups: [ 'list', 'indent', 'blocks', 'align', 'bidi' ], items: [ 'NumberedList', 'BulletedList', '-', 'Outdent', 'Indent', '-', 'Blockquote', 'CreateDiv', '-', 'JustifyLeft', 'JustifyCenter', 'JustifyRight', 'JustifyBlock' ] },
        '/',
        { name: 'styles', items: [ 'Styles', 'Format', 'Font', 'FontSize' ] },
        { name: 'colors', items: [ 'TextColor', 'BGColor' ] },
        { name: 'basicstyles', groups: [ 'basicstyles', 'cleanup' ], items: [ 'Bold', 'Italic', 'Underline', 'Strike', 'Subscript', 'Superscript', '-', 'RemoveFormat' ] }
    ];

    config.toolbar_mini = [
        { name: 'paragraph', groups: [ 'list', 'indent', 'blocks', 'align', 'bidi' ], items: [ 'NumberedList', 'BulletedList', '-', 'Outdent', 'Indent', '-', 'Blockquote', 'CreateDiv', '-', 'JustifyLeft', 'JustifyCenter', 'JustifyRight', 'JustifyBlock' ] },
        { name: 'styles', items: [ 'Font', 'FontSize' ] },
        { name: 'colors', items: [ 'TextColor', 'BGColor' ] },
        { name: 'basicstyles', groups: [ 'basicstyles', 'cleanup' ], items: [ 'Bold', 'Italic', 'Underline', 'Strike', 'Subscript', 'Superscript', '-', 'RemoveFormat' ] },
        { name: 'insert', items: [ 'Image', 'Table', 'HorizontalRule', 'SpecialChar' ] }
    ];
};

