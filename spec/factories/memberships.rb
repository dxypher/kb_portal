FactoryBot.define do
  factory :membership do
    user
    team
    role { 'member' }
  end
end
