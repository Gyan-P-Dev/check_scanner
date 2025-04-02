module OcrExtractor
  extend ActiveSupport::Concern

  def with_tempfile(data)
    Tempfile.create(["ocr_check", ".png"], Rails.root.join("tmp")) do |file|
      file.binmode
      file.write(data)
      file.rewind
      yield file.path
    end
  end

  def extract_text(image_path)
    RTesseract.new(image_path.to_s).to_s
  end

  def extract_company_from_text(text)
    # Remove unnecessary spaces and normalize the text
    text = text.gsub(/\s+/, " ").strip

    # Exclude common false matches like "PAY", "TO", "CHECK", etc.
    blacklist = %w[PAY TO CHECK DOLLARS AMOUNT DATE BALANCE REFERENCE]

    # Find all uppercase word phrases that seem like a company name
    matches = text.scan(/\b[A-Z][A-Z\s]+(?:INC|CORP|LLC|LTD|BANK|SECURED)?\b/)

    # Filter out blacklisted words and return the most relevant match
    matches.reject! { |name| blacklist.any? { |word| name.include?(word) } }

    # Prioritize names with keywords like "INC", "LLC", "SECURED", etc.
    priority_match = matches.find { |name| name.match?(/\b(INC|CORP|LLC|LTD|SECURED|BANK)\b/) }

    # Return the best match (priority first, otherwise first valid name)
    priority_match || matches.first
  end

  def find_check_number(text)
    # Extract check number - appears as a 5-digit number after a date
    match = text.match(/\b\d{1,2}\/\d{1,2}\/\d{4}\s+(\d{5})\b/)
    match ? match[1] : nil
  end

  def find_invoice_references(text)
    references = []

    # Identify lines that contain reference numbers
    text.each_line do |line|
      # Match a row with Date, Type, Reference, and other columns
      if line.match?(/\d{1,2}\/\d{1,2}\/\d{4}\s+\w+\s+\d{4,6}/)
        # Extract reference number (assumed to be the 3rd numeric column)
        columns = line.split(/\s+/)
        reference = columns[2] # Adjust index if needed based on OCR spacing
        references << reference if reference.match?(/^\d{4,6}$/)
      end
    end

    references.uniq
  end
end
