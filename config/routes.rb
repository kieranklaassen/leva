Leva::Engine.routes.draw do
  root "workbench#index"

  get "design_system", to: "design_system#index"

  resources :optimization_runs, only: [ :show ]
  resources :fine_tune_runs, only: [ :show ]

  resources :datasets do
    resources :dataset_records, path: "records", only: [ :index, :show ]
    resource :optimization, only: [ :new, :create ], controller: "dataset_optimizations"
    resources :fine_tune_runs, only: [ :create ]
  end
  resources :experiments, except: [ :destroy ] do
    member do
      post :rerun
    end
    resources :runner_results, only: [ :show ]
  end
  resources :prompts
  resources :workbench, only: [ :index, :new, :create, :edit, :update ] do
    collection do
      post "run"
      post "run_all_evals"
      post "run_evaluator"
    end
  end
end
