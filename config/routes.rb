Sherwinkeys::Application.routes.draw do
  root to: "pages#home"
  match 'ember', to: "pages#ember"
end
