class Check < ApplicationRecord
  belongs_to :company
  has_many :check_invoices
  has_many :invoices, through: :check_invoices

  has_one_attached :image
  validates :image, attached: true
  before_save :extract_details, if: -> { image.attached? }

  private

  def extract_details
    return unless image.attached?

    # Convert ActiveStorage file to local path
    file_path = ActiveStorage::Blob.service.path_for(image.key)

    # Preprocess Image (Optional: Improve OCR Accuracy)
    preprocessed_image_path = preprocess_image(file_path)

    # Extract text from image
    extracted_text = RTesseract.new(preprocessed_image_path, lang: "eng", psm: 6).to_s

    # Parse extracted text
    self.number = extracted_text[/\b\d{5,}\b/]  # Extract check number
    self.amount = extracted_text[/\$\d+(\.\d{2})?/].to_s.gsub("$", "").to_f  # Extract amount
    self.date = extracted_text[/\d{2}\/\d{2}\/\d{4}/]  # Extract date (MM/DD/YYYY)
  end

  def preprocess_image(image_path)
    processed_path = "#{Rails.root}/tmp/processed_check.png"
    image = MiniMagick::Image.open(image_path)
    image.resize "1000x1000"
    image.colorspace "Gray"
    image.contrast
    image.write processed_path
    processed_path
  end
end
