class ChecksController < ApplicationController
  include OcrExtractor # Moved OCR logic to a Concern

  skip_before_action :verify_authenticity_token, only: [:extract_company]
  protect_from_forgery with: :exception

  def new
    @check = Check.new
  end

  def create
    @check = Check.new(check_params)

    if @check.save
      CheckProcessor.new(@check, params[:check][:invoice_numbers]).process!
      redirect_to checks_path, notice: "Check successfully created!"
    else
      render :new
    end
  end

  def index
    @checks = Check.includes(:company, :invoices).order(created_at: :desc)
  end

  def extract_attributes
    require "rtesseract"

    begin
      uploaded_file = params[:image]
      with_tempfile(uploaded_file.read) do |file_path|
        extracted_text = extract_text(file_path)
        company_name = extract_company_from_text(extracted_text)
        check_number = find_check_number(extracted_text)
        invoice_numbers = find_invoice_references(extracted_text)

        @company = Company.find_or_create_by(name: company_name) if company_name

        render json: {
                 company_name: company_name,
                 company_id: @company&.id,
                 check_number: check_number,
                 invoice_numbers: invoice_numbers,
                 exists: @company.present?,
               }
      end
    rescue => e
      Rails.logger.warn("Image processing failed: #{e.message}")
      render json: { error: "Something went wrong while processing the image." }, status: :unprocessable_entity
    end
  end

  private

  def check_params
    params.require(:check).permit(:image, :company_id, :number, invoice_ids: [])
  end
end
