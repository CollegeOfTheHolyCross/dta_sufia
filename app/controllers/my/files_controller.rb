module My
  class FilesController < MyController
    self.search_params_logic += [
        #:show_only_resources_deposited_by_current_user,
        :show_only_generic_files
    ]

    before_filter :admin_files_facets_config, :only => [:index, :facet]

    def index
      super
      @selected_tab = :files
    end


    def admin_files_facets_config
      blacklight_config.facet_fields['publisher_ssim'].show = true
      blacklight_config.facet_fields['publisher_ssim'].if = true
    end

    protected

    def search_action_url(*args)
      sufia.dashboard_files_url(*args)
    end
  end
end
