FactoryBot.define do
  factory :doc do
    team
    title { 'Onboarding' }
    body { 'Welcome!' }
  end
end
