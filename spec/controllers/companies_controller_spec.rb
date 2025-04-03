require "rails_helper"

RSpec.describe CompaniesController, type: :controller do
  describe "GET #index" do
    before do
      Company.destroy_all # Clears existing records before each test
    end

    let!(:company1) { create(:company, name: "Company One") }
    let!(:company2) { create(:company, name: "Company Two") }

    it "assigns all companies as @companies" do
      get :index
      expect(assigns(:companies)).to match_array([company1, company2])
    end

    it "renders the index template" do
      get :index
      expect(response).to render_template(:index)
    end

    it "returns a successful response" do
      get :index
      expect(response).to have_http_status(:success)
    end
  end
end
