Rails.application.routes.draw do
  get "invoices/index"
  root "checks#new"
  resources :checks, only: [:create, :index, :new]
  resources :invoices, only: [:index]
  resources :companies
  post "extract_attributes", to: "checks#extract_attributes"
end
