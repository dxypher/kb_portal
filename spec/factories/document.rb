FactoryBot.define do
  factory :document do
    team
    title { 'Onboarding' }
    body { 'Welcome!' }
  end
end
