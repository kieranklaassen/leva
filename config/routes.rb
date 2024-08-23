Leva::Engine.routes.draw do
  root 'workbench#index'

  resources :datasets do
    resources :dataset_records, path: 'records', only: [:index, :show]
  end
  resources :experiments, except: [:destroy] do
    resources :runner_results, only: [:show]
  end
  resources :prompts
  resources :workbench, only: [:index, :new, :create, :edit, :update] do
    collection do
      post 'run'
      post 'run_all_evals'
      post 'run_evaluator'
    end
  end
end