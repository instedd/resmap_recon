require_relative '../app/resmap/rack/api_forwarder.rb'

ResmapRecon::Application.routes.draw do
  mount ::Resmap::Rack::ApiForwarder.new, at: '/rm'

  devise_for :users, controllers: {omniauth_callbacks: "omniauth_callbacks"}
  guisso_for :user

  resources :projects, only: [:index, :show, :new, :create] do
    member do
      get 'curate'
      get 'pending_changes'
      post 'dismiss_source_sites'
    end
    resources :sources, controller: 'project_sources', only: [:new, :index, :destroy] do
      resources :sites, controller: 'project_sources_sites', only: [] do
      end
      member do
        get 'source_list_details'
        get 'source_list_sites_with_mfl_id_csv'
        get 'unmapped_csv_download'
        post 'process_automapping'
        post 'reupload_source_list'

        get 'after_create'
        get 'invalid'
        get 'upload_new_file'

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
      get 'csv_download_from_rm', controller: :project_master_sites
      resources :sites, controller: 'project_master_sites', only: [] do
        collection do
          get 'index'
          post 'create'
          get 'search'
          get 'find_duplicates'
          get 'map'
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
