class CreateChecks < ActiveRecord::Migration[7.1]
  def change
    create_table :checks do |t|
      t.string :number
      t.decimal :amount
      t.date :date
      t.string :image
      t.references :company, null: false, foreign_key: true

      t.timestamps
    end
  end
end
