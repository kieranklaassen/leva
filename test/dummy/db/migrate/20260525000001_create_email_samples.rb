# frozen_string_literal: true

class CreateEmailSamples < ActiveRecord::Migration[7.2]
  def change
    create_table :email_samples do |t|
      t.string :type, null: false, default: "EmailSample" # STI: EmailSample | EmailRoutingSample
      t.string :from
      t.string :from_name
      t.string :subject
      t.text :body
      t.string :category, null: false
      t.string :routing # inbox | briefed | archived (derived from the Cora category -> action mapping)

      t.timestamps
    end

    add_index :email_samples, :type
    add_index :email_samples, :category
    add_index :email_samples, :routing
  end
end
