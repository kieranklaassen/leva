class CreateLevaDatasets < ActiveRecord::Migration[7.2]
  def change
    create_table :leva_datasets do |t|
      t.string :name

      t.timestamps
    end
  end
end