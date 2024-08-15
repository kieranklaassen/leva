Leva::Engine.routes.draw do
  root 'workbench#index'

  resources :datasets
  resources :experiments, except: [:destroy]
  resources :prompts
  resources :workbench, only: [:index, :new, :create, :edit, :update] do
    collection do
      post 'run'
      post 'run_with_evaluation'
      post 'run_evaluator'
    end
  end
end