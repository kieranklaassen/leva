class CreateTextContents < ActiveRecord::Migration[7.2]
  def change
    create_table :text_contents do |t|
      t.text :text
      t.string :expected_label

      t.timestamps
    end
  end
end
