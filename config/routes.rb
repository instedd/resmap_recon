ResmapRecon::Application.routes.draw do

  resource :session, only: [:new, :create, :destroy]

  resources :projects, only: [:index, :show, :new, :create] do
    member do
      get 'curate'
      get 'pending_changes'
    end
    resources :sources, controller: 'project_sources', only: [:new] do
      resources :sites, controller: 'project_sources_sites', only: [] do
        member do
          post 'dismiss'
        end
      end
      member do
        get 'review_mapping'
        get 'source_list_details'
        post 'update_mapping_entry'
        post 'update_mapping_property'
        get 'unmapped_csv_download'

        get 'after_create'

        resource 'import_wizard', controller: 'project_sources_import_wizard', only: [] do
          post 'validate'
          post 'start'
          get 'status'
        end
      end
      collection do
        get 'review_mapping'
        post 'create_from_file'
        post 'create_from_collection'
      end
    end
    resource :master, only: [] do
      get 'csv_download', controller: :project_master_sites
      resources :sites, controller: 'project_master_sites', only: [] do
        collection do
          get 'index'
          post 'create'
          get 'search'
        end
        member do
          post 'update'
          get 'consolidated_sites'
          get 'history'
        end
      end
    end
    resources :members, controller: 'project_members', only: [:index, :destroy, :create] do
      collection do
        get 'typeahead'
      end
    end
  end

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
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

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
