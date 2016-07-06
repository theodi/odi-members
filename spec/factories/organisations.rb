# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :organisation do
    name        { Faker::Company.name }
    description { Faker::Company.catch_phrase }
    url         { Faker::Internet.url }
  end
end
