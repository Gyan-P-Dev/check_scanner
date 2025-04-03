require "rails_helper"

RSpec.describe ChecksController, type: :controller do
  let(:company) { Company.create(name: "Test Company") }
  let(:check) { Check.create(company: company, number: "12345") }
  let(:valid_attributes) { { company_id: company.id, number: "12345", image: fixture_file_upload("spec/fixtures/files/sample_check.jpg", "image/jpg") } }
  let(:invalid_attributes) { { company_id: nil, number: "", image: nil } }

  before do
    check.reload
  end

  let!(:check) { create(:check, number: "12345") }

  describe "GET #index" do
    it "assigns all checks as @checks" do
      get :index
      expect(assigns(:checks)).to include(check)
    end

    it "renders the index template" do
      get :index
      expect(response).to render_template(:index)
    end
  end

  describe "GET #new" do
    it "assigns a new check as @check" do
      get :new
      expect(assigns(:check)).to be_a_new(Check)
    end

    it "renders the new template" do
      get :new
      expect(response).to render_template(:new)
    end
  end

  describe "POST #create" do
    context "with valid parameters" do
      it "creates a new check" do
        expect {
          post :create, params: { check: valid_attributes }
        }.to change(Check, :count).by(1)
      end

      it "redirects to the checks index" do
        post :create, params: { check: valid_attributes }
        expect(response).to redirect_to(checks_path)
      end
    end

    context "with invalid parameters" do
      it "does not create a new check" do
        expect {
          post :create, params: { check: invalid_attributes }
        }.to_not change(Check, :count)
      end

      it "re-renders the new template" do
        post :create, params: { check: invalid_attributes }
        expect(response).to render_template(:new)
      end
    end
  end

  describe ChecksController, type: :controller do
    describe "POST #extract_attributes" do
      let!(:existing_company) { create(:company, name: "Existing Company") }
      let(:image) { fixture_file_upload("spec/fixtures/files/sample_check.jpg", "image/jpeg") }

      before do
        allow_any_instance_of(ChecksController).to receive(:extract_text).and_return("Company: Test Company\nCheck Number: 12345\nInvoice: INV1001")
        allow_any_instance_of(ChecksController).to receive(:extract_company_from_text).and_return("Test Company")
        allow_any_instance_of(ChecksController).to receive(:find_check_number).and_return("12345")
        allow_any_instance_of(ChecksController).to receive(:find_invoice_references).and_return(["INV1001"])
      end

      it "returns extracted attributes as JSON" do
        post :extract_attributes, params: { image: image }, as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response["company_name"]).to eq("Test Company")
        expect(json_response["check_number"]).to eq("12345")
        expect(json_response["invoice_numbers"]).to eq(["INV1001"])
      end

      it "returns an error message if image processing fails" do
        allow_any_instance_of(ChecksController).to receive(:extract_text).and_raise(StandardError, "Processing error")

        post :extract_attributes, params: { image: image }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Something went wrong while processing the image.")
      end
    end
  end
end
