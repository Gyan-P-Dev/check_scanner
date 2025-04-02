class CheckProcessor
  def initialize(check, invoice_numbers)
    @check = check
    @invoice_numbers = invoice_numbers&.split(",")&.map(&:strip) || []
  end

  def process!
    @invoice_numbers.each do |invoice_number|
      invoice = Invoice.find_or_create_by(number: invoice_number, company_id: @check.company_id)
      CheckInvoice.create!(check: @check, invoice: invoice) if invoice
    end
  end
end
