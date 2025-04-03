class CreateCheckInvoices < ActiveRecord::Migration[7.1]
  def change
    create_table :check_invoices do |t|
      t.references :check, null: false, foreign_key: true
      t.references :invoice, null: false, foreign_key: true

      t.timestamps
    end
  end
end
