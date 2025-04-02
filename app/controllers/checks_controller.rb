class ChecksController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:extract_company]
  protect_from_forgery with: :exception

  def new
    @check = Check.new
  end

  def create
    @check = Check.new(check_params)

    if @check.save
      invoice_numbers = params[:check][:invoice_numbers]&.split(",").map(&:strip)

      invoice_numbers.each do |invoice_number|
        invoice = Invoice.find_or_create_by(number: invoice_number, company_id: @check.company_id)

        if invoice
          CheckInvoice.create!(check: @check, invoice: invoice)
        else
          Rails.logger.error "❌ Invoice with number #{invoice_number} not found!"
        end
      end

      redirect_to checks_path, notice: "Check successfully created!"
    else
      render :new
    end
  end

  def index
    @checks = Check.all
  end

  def extract_company
    require "rtesseract"

    uploaded_file = params[:image]
    file_path = Rails.root.join("tmp", uploaded_file.original_filename)

    # file_path = Rails.root.join("tmp", "ocr_check.png").to_s  # Convert to string
    File.open(file_path, "wb") { |file| file.write(uploaded_file.read) }

    extracted_text = RTesseract.new(file_path.to_s).to_s
    company_name = extract_company_from_text(extracted_text)
    check_number = find_check_number(extracted_text)
    invoice_numbers = find_invoice_numbers(extracted_text)

    existing_company = if Company.find_by(name: company_name)
        @company = Company.find_by(name: company_name)
        true
      else
        @company = Company.find_or_create_by(name: company_name)
        false
      end

    render json: {
      company_name: company_name,
      company_id: @company.id,
      check_number: check_number,
      invoice_numbers: invoice_numbers,
      exists: existing_company.present?,
    }
  end

  private

  def check_params
    params.require(:check).permit(:image, :company_id, :number, invoice_ids: [])
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

  def find_invoice_numbers(text)
    matches = text.scan(/\b\d{3,6}[a-zA-Z]?\b/) # Finds numbers like "5101" and "608a"
    matches.uniq
  end
end
