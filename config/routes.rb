require './lib/api_constraints'

Rails.application.routes.draw do
  namespace :api, constraints: {format: 'json', subdomain: 'api'}, path: '/' do
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      resources :notes
      resources :contacts
    end

    scope module: :v2, constraints: ApiConstraints.new(version: 2) do
      resources :notes
      resources :contacts
    end
  end

  # Must be the last route
  match '*unknown_path', :to => 'application#routing_error', via: :all
end
