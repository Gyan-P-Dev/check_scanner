require "rails_helper"

RSpec.describe OcrExtractor do
  let(:dummy_class) { Class.new { include OcrExtractor }.new }

  describe "#with_tempfile" do
    it "creates a temporary file and yields its path" do
      test_data = "Test data"
      dummy_class.with_tempfile(test_data) do |file_path|
        expect(File.exist?(file_path)).to be true
        expect(File.read(file_path)).to eq test_data
      end
    end
  end

  describe "#extract_text" do
    it "extracts text from a given image path" do
      image_path = Rails.root.join("spec", "fixtures", "files", "sample_check.jpg")
      allow(RTesseract).to receive(:new).with(image_path.to_s).and_return(double(to_s: "Extracted Text"))

      result = dummy_class.extract_text(image_path)
      expect(result).to eq "Extracted Text"
    end
  end

  describe "#extract_company_from_text" do
    it "extracts the correct company name from text" do
      text = "PAY TO ACME CORP CHECK #12345"
      result = dummy_class.extract_company_from_text(text)
      expect(result).to eq "ACME CORP"
    end

    it "returns nil if no company is found" do
      text = "PAY TO CHECK 12345"
      result = dummy_class.extract_company_from_text(text)
      expect(result).to be_nil
    end
  end

  describe "#find_check_number" do
    it "extracts the check number from text" do
      text = "01/01/2025 12345"
      result = dummy_class.find_check_number(text)
      expect(result).to eq "12345"
    end

    it "returns nil when no check number is found" do
      text = "No check number here"
      result = dummy_class.find_check_number(text)
      expect(result).to be_nil
    end
  end

  describe "#find_invoice_references" do
    it "extracts invoice reference numbers from text" do
      text = "01/01/2025 INV 123456\n01/02/2025 REF 654321"
      result = dummy_class.find_invoice_references(text)
      expect(result).to eq ["123456", "654321"]
    end

    it "returns an empty array when no invoice references are found" do
      text = "No references here"
      result = dummy_class.find_invoice_references(text)
      expect(result).to eq []
    end
  end
end
