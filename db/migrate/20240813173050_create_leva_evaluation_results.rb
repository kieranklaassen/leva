class CreateLevaEvaluationResults < ActiveRecord::Migration[7.2]
  def change
    create_table :leva_evaluation_results do |t|
      t.references :experiment, null: false, foreign_key: true
      t.references :dataset_record, null: false, foreign_key: true
      t.string :prediction
      t.float :score
      t.string :label

      t.timestamps
    end
  end
end