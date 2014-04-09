require_relative '../app/resmap/rack/api_forwarder.rb'

ResmapRecon::Application.routes.draw do
  mount ::Resmap::Rack::ApiForwarder.new, at: '/rm'

  devise_for :users, controllers: {omniauth_callbacks: "omniauth_callbacks"}
  guisso_for :user

  resources :projects, only: [:index, :show, :new, :create] do
    member do
      get 'curate'
      get 'pending_changes'
    end
    resources :sources, controller: 'project_sources', only: [:new, :index, :destroy] do
      resources :sites, controller: 'project_sources_sites', only: [] do
        member do
          post 'dismiss'
        end
      end
      member do
        get 'source_list_details'
        get 'unmapped_csv_download'
        get 'promote_facilities'
        post 'promote_site'
        post 'process_automapping'
        post 'reupload_source_list'

        get 'after_create'
        get 'invalid'

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
          get 'find_duplicates'
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


  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

end
