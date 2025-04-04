class ChecksController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:extract_company]
  protect_from_forgery with: :exception

  def new
    @check = Check.new
  end

  def create
    @check = Check.new(check_params.except(:invoice_numbers))
    if params["check"][:company_id].present? && !(params[:company_name].present?)
      @company = Company.find(params["check"][:company_id])
    elsif params[:company_name].present?
      @company ||= Company.find_or_create_by(name: params[:company_name])
    end

    @check.company_id = @company.id

    if @check.save
      invoice_numbers = params[:check][:invoice_numbers]&.split(",").map(&:strip)

      invoice_numbers.each do |invoice_number|
        invoice = Invoice.find_or_create_by(invoice_number: invoice_number, company_id: @check.company_id, check_id: @check.id)

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

  def extract_attributes
    require "rtesseract"
    begin
      uploaded_file = params[:image]
      file_path = Rails.root.join("tmp", uploaded_file.original_filename)

      # file_path = Rails.root.join("tmp", "ocr_check.png").to_s  # Convert to string
      File.open(file_path, "wb") { |file| file.write(uploaded_file.read) }

      extracted_text = RTesseract.new(file_path.to_s).to_s
      company_name = extract_company_from_text(extracted_text)
      check_number = find_check_number(extracted_text)
      invoice_numbers = find_invoice_references(extracted_text)

      existing_company = if Company.find_by(name: company_name)
          @company = Company.find_by(name: company_name)
          true
        elsif company_name
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
    rescue => e
      Rails.logger.warn("Image processing failed: #{e.message}")
      render json: { error: "Something went wrong while processing the image." }, status: :unprocessable_entity
    end
  end

  private

  def check_params
    params.require(:check).permit(:image, :invoice_numbers, :company_id, :number, invoice_ids: [])
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
