class CheckInvoice < ApplicationRecord
  belongs_to :check
  belongs_to :invoice
end
