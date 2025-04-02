class Check < ApplicationRecord
  belongs_to :company
  has_many :check_invoices, dependent: :destroy
  has_many :invoices, through: :check_invoices

  has_one_attached :image
  validates :image, attached: true
  after_commit :extract_details, on: :create

  private

  def extract_details
    return unless image.attached?

    # Convert ActiveStorage file to a temporary local file
    file = Tempfile.new(["check_image", ".png"], Rails.root.join("tmp"))
    file.binmode
    file.write(image.download)
    file.rewind
    file_path = file.path

    # Preprocess Image (Optional: Improve OCR Accuracy)
    preprocessed_image_path = preprocess_image(file_path)

    # Extract text from image using Tesseract
    extracted_text = RTesseract.new(preprocessed_image_path, lang: "eng", psm: 6).to_s

    # Parse extracted text
    self.number = extracted_text[/\b\d{5,}\b/]  # Extract check number
    self.amount = extracted_text[/\$\d+(\.\d{2})?/].to_s.gsub("$", "").to_f  # Extract amount
    self.date = extracted_text[/\d{2}\/\d{2}\/\d{4}/]  # Extract date (MM/DD/YYYY)

    # Close and unlink temporary file
    file.close
    file.unlink
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
