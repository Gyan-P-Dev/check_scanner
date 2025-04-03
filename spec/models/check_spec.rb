require "rails_helper"

RSpec.describe Check, type: :model do
  before do
    ActiveRecord::Base.connection.reconnect!
  end

  describe "associations" do
    it { is_expected.to belong_to(:company) }
    it { is_expected.to have_many(:check_invoices).dependent(:destroy) }
    it { is_expected.to have_many(:invoices).through(:check_invoices) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:image) }

    it "validates image format" do
      check = Check.new(company: Company.create(name: "Test Company"))
      check.image.attach(io: File.open(Rails.root.join("spec/fixtures/files/sample_text.txt")),
                         filename: "sample_text.txt", content_type: "text/plain")

      expect(check).not_to be_valid
      expect(check.errors[:image]).to include("must be a JPEG or PNG")
    end
  end

  describe "image processing" do
    let(:company) { Company.create(name: "Test Company") }
    let(:valid_image) { fixture_file_upload("sample_check.jpg", "image/png") }

    it "attaches an image" do
      check = Check.create(company: company, image: valid_image)
      expect(check.image).to be_attached
    end
  end
end
