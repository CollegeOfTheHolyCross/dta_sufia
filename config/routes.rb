Rails.application.routes.draw do
  mount Ckeditor::Engine => '/ckeditor'
  resources :institutions

  resources :homosaurus

  resources :posts, path: :news

  mount Qa::Engine => '/qa'

  
  blacklight_for :catalog
  devise_for :users
  mount Hydra::RoleManagement::Engine => '/'

  Hydra::BatchEdit.add_routes(self)

  get 'files/regenerate/:id' => 'generic_files#regenerate', as: :generic_file_regenerate
  get 'files/swap_visibility/:id' => 'generic_files#swap_visibility', as: :generic_file_visibility

  get 'admin/reload' => 'commands#update', as: :reload_app
  get 'proxy' => 'commands#proxy'
  get 'proxy_raw' => 'commands#proxy_raw'
  get 'admin/reindex' => 'commands#reindex', as: :reindex_all
  get 'admin/restart_resque' => 'commands#restart_resque', as: :restart_resque
  get 'admin/actions' => 'commands#admin_actions', as: :admin_actions
  get 'collections/member_visibility/:id' => 'collections#change_member_visibility', as: :collection_member_visibility
  get 'collections/collection_invisible/:id' => 'collections#collection_invisible', as: :collection_invisible
  get 'collections/collection_visible/:id' => 'collections#collection_visible', as: :collection_visible

  #Static Paths
  resources :abouts, only: [:new, :edit, :create, :update, :show], :path => :about
  resources :learns, only: [:new, :edit, :create, :update, :show], :path => :learn

  get 'feedback' => 'abouts#feedback', as: :feedback
  post 'feedback' => 'abouts#feedback'
  get 'feedback_complete' => 'abouts#feedback_complete', as: :feedback_complete
  get 'subscribe' => 'abouts#subscribe', as: :subscribe

  #get 'about' => 'about#index', as: :about
  get 'about/project' => 'abouts#project', as: :about_project
  #get 'about/news' => 'abouts#news', as: :about_news
  get 'about/team' => 'abouts#team', as: :about_team
  get 'about/board' => 'abouts#board', as: :about_board
  get 'about/policies' => 'abouts#policies', as: :about_policies
  get 'about/contact' => 'abouts#contact', as: :about_contact

  get 'places', :to => 'catalog#map', :as => 'places'

  get 'col', :to => 'collections#public_index', :as => 'collections_public'
  get 'col/:id', :to => 'collections#public_show', :as => 'collections_public_show'
  get 'col/facet/:id', :to => 'collections#facet', :as => 'collections_facet'

  get 'inst', :to => 'institutions#public_index', :as => 'institutions_public'
  get 'inst/:id', :to => 'institutions#public_show', :as => 'institutions_public_show'
  get 'inst/facet/:id', :to => 'institutions#facet', :as => 'institutions_facet'

  get 'ajax/cols/:id', :to => 'institutions#update_collections', :as => 'generic_files_update_collections'
  get 'ajax/cols', :to => 'institutions#update_collections', :as => 'generic_files_update_collections_no_id'

  # formats browse
  get 'genre', :to => 'catalog#genre_facet', :as => 'genre_facet'

  # subject browse
  get 'topic', :to => 'catalog#topic_facet', :as => 'topic_facet'

  # recently added browse

  resources 'oai',
            only: [:index]
  
  # This must be the very last route in the file because it has a catch-all route for 404 errors.
    # This behavior seems to show up only in production mode.
    mount Sufia::Engine => '/'

  root to: 'homepage#index'




  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
