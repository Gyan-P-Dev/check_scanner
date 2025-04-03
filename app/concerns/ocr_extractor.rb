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
    text = text.gsub(/\s+/, " ").strip

    blacklist = %w[PAY TO CHECK DOLLARS AMOUNT DATE BALANCE REFERENCE]

    # Extract full uppercase company names, ensuring we do NOT capture blacklisted words
    matches = text.scan(/\b((?!(?:#{blacklist.join("|")})\b)[A-Z]+(?:\s+[A-Z]+)*\s+(?:INC|CORP|LLC|LTD|BANK|SECURED))\b/).flatten

    puts "Extracted Matches: #{matches.inspect}" # Debugging output

    # Prioritize names with business suffixes
    priority_match = matches.find { |name| name.match?(/\b(INC|CORP|LLC|LTD|SECURED|BANK)\b/) }

    priority_match || matches.first
  end

  def find_check_number(text)
    match = text.match(/\b\d{1,2}\/\d{1,2}\/\d{4}\s+(\d{5})\b/)
    match ? match[1] : nil
  end

  def find_invoice_references(text)
    references = []

    text.each_line do |line|
      if line.match?(/\d{1,2}\/\d{1,2}\/\d{4}\s+\w+\s+\d{4,6}/)
        columns = line.split(/\s+/)
        reference = columns[2]
        references << reference if reference.match?(/^\d{4,6}$/)
      end
    end

    references.uniq
  end
end
