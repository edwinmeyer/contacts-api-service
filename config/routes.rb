require './lib/api_constraints'

Rails.application.routes.draw do
  namespace :api, constraints: {format: 'json'} do
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true)  do
      resources :notes
      resources :contacts
    end

    scope module: :v2, constraints: ApiConstraints.new(version: 2) do
      resources :notes
      resources :contacts
    end
  end
end
