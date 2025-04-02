class InvoicesController < ApplicationController
  def index
    @invoices = Invoice.includes(:company, :check).all
  end
end
