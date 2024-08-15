Leva::Engine.routes.draw do
  root 'workbench#index'

  resources :datasets
  resources :experiments, except: [:destroy]
  resources :prompts
  resources :workbench, only: [:index, :new, :show] do
    post 'run', on: :collection
    post 'run_with_evaluation', on: :collection
    post 'run_evaluator', on: :collection
  end
end