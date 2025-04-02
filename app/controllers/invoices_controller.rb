class InvoicesController < ApplicationController
  def index
    @invoices = Invoice.includes(:company, :checks).all
  end
end
