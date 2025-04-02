class Company < ApplicationRecord
  has_many :checks, dependent: :destroy
  has_many :invoices, dependent: :destroy
end
