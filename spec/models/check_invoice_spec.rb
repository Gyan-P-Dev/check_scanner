require "rails_helper"

RSpec.describe CheckInvoice, type: :model do
  describe "associations" do
    it { should belong_to(:check) }
    it { should belong_to(:invoice) }
  end
end
