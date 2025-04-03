require "rails_helper"

RSpec.describe InvoicesController, type: :controller do
  describe "GET #index" do
    let!(:company) { create(:company, name: "Test Company") }
    before do
      Invoice.destroy_all
    end

    let!(:invoices) do
      [
        Invoice.create!(number: "INV1", company: company),
        Invoice.create!(number: "INV2", company: company),
      ]
    end

    before { get :index }

    it "assigns all invoices as @invoices" do
      expect(assigns(:invoices)).to match_array(invoices)
    end

    it "preloads company and checks associations" do
      invoices = assigns(:invoices)
      expect(invoices).to all(have_attributes(company: company))
      expect(invoices).to all(satisfy { |inv| inv.association(:checks).loaded? })
    end

    it "renders the index template" do
      expect(response).to render_template(:index)
    end

    it "returns a successful response" do
      expect(response).to have_http_status(:success)
    end
  end
end
