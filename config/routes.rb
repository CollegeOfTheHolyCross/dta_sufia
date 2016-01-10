Rails.application.routes.draw do
  resources :institutions

  resources :homosaurus

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
  get 'collections/member_visibility/:id' => 'collections#change_member_visibility', as: :collection_member_visibility

  #Static Paths
  get 'about' => 'about#index', as: :about
  get 'about/project' => 'about#project', as: :about_project
  get 'about/contact' => 'about#contact', as: :about_contact

  get 'places', :to => 'catalog#map', :as => 'places'

  get 'collections', :to => 'collections#public_index', :as => 'collections_public'
  get 'collections/show/:id', :to => 'collections#public_show', :as => 'collections_public_show'
  get 'collections/facet/:id', :to => 'collections#facet', :as => 'collections_facet'

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
