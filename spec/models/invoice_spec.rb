require "rails_helper"

RSpec.describe Invoice, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:company) }
    it { is_expected.to have_many(:check_invoices).dependent(:destroy) }
    it { is_expected.to have_many(:checks).through(:check_invoices) }
  end

  describe "validations" do
    let(:company) { create(:company) }  # Ensure a valid company exists
    subject { create(:invoice, company: company) }  # Create a valid invoice

    it { is_expected.to validate_presence_of(:number) }
    it { is_expected.to validate_uniqueness_of(:number).scoped_to(:company_id) }
  end
end
