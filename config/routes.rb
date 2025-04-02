Rails.application.routes.draw do
  get "invoices/index"
  resources :checks
  resources :invoices, only: [:index]
  resources :companies
  post "extract_company", to: "checks#extract_company"
end
