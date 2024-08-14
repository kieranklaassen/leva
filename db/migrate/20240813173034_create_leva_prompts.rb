class CreateLevaPrompts < ActiveRecord::Migration[7.2]
  def change
    create_table :leva_prompts do |t|
      t.string :name
      t.integer :version
      t.text :system_prompt
      t.text :user_prompt
      t.text :metadata

      t.timestamps
    end
  end
end
