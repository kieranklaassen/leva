module Leva
  class DatasetRecordsController < ApplicationController
    before_action :set_dataset

    # GET /datasets/:dataset_id/records
    def index
      @records = @dataset.dataset_records.includes(:recordable)
    end

    # GET /datasets/:dataset_id/records/:id
    def show
      @record = @dataset.dataset_records.find(params[:id])
    end

    private

    def set_dataset
      @dataset = Dataset.find(params[:dataset_id])
    end
  end
end