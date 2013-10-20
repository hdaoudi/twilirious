Twilirious::Application.routes.draw do
  match ':controller(/:action(.:format))', via: :get
  match ':controller(/:action(/:id(.:format)))', via: :get
  root :to => 'message#index'
end
