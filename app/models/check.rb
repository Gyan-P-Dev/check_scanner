class Check < ApplicationRecord
  belongs_to :company
  has_many :check_invoices, dependent: :destroy
  has_many :invoices, through: :check_invoices

  has_one_attached :image
  validates :image, attached: true
  after_commit :extract_details, on: :create
  validate :correct_image_type

  private

  def extract_details
    return unless image.attached?

    with_tempfile(image.download) do |file_path|
      preprocessed_image_path = preprocess_image(file_path)
      extracted_text = extract_text(preprocessed_image_path)
      assign_extracted_details(extracted_text)
    end
  end

  def with_tempfile(data)
    Tempfile.create(["check_image", ".png"], Rails.root.join("tmp")) do |file|
      file.binmode
      file.write(data)
      file.rewind
      yield file.path
    end
  end

  def extract_text(image_path)
    RTesseract.new(image_path, lang: "eng", psm: 6).to_s
  end

  def assign_extracted_details(text)
    self.number = text[/\b\d{5,}\b/]  # Extract check number
    self.amount = text[/\$\d+(\.\d{2})?/].to_s.delete("$").to_f  # Extract amount
    self.date = text[/\d{2}\/\d{2}\/\d{4}/]  # Extract date (MM/DD/YYYY)
  end

  def correct_image_type
    return unless image.attached?

    allowed_types = %w[image/jpeg image/png image/jpg]
    errors.add(:image, "must be a JPEG or PNG") unless image.content_type.in?(allowed_types)
  end

  def preprocess_image(image_path)
    processed_path = "#{Rails.root}/tmp/processed_check.png"
    MiniMagick::Image.open(image_path).tap do |image|
      image.resize "1000x1000"
      image.colorspace "Gray"
      image.contrast
      image.write processed_path
    end
    processed_path
  end
end
