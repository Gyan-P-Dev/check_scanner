FactoryBot.define do
  factory :invoice do
    sequence(:number) { |n| "INV#{n}" } # Ensures unique invoice numbers
    company
  end
end
