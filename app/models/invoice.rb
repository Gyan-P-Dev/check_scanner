class Invoice < ApplicationRecord
  belongs_to :company
  belongs_to :check
end
