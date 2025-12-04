class CreateEmailContents < ActiveRecord::Migration[7.2]
  def change
    create_table :email_contents do |t|
      t.string :subject
      t.text :body
      t.string :category

      t.timestamps
    end
  end
end
