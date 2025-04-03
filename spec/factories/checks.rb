FactoryBot.define do
  factory :check do
    number { "12345" }
    company { create(:company) }
    image { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/sample_check.jpg"), "image/jpeg") }
  end
end
