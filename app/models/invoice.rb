class Invoice < ApplicationRecord
  has_many :check_invoices, dependent: :destroy
  has_many :checks, through: :check_invoices
  belongs_to :company
end
