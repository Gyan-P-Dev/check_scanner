class CreateInvoices < ActiveRecord::Migration[7.1]
  def change
    create_table :invoices do |t|
      t.string :invoice_number
      t.references :company, null: false, foreign_key: true
      t.references :check, null: false, foreign_key: true

      t.timestamps
    end
  end
end
