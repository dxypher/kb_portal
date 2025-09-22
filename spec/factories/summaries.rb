FactoryBot.define do
  factory :summary do
    document { nil }
    team { nil }
    content { "MyText" }
    llm_name { "MyString" }
    tokens_in { 1 }
    tokens_out { 1 }
    latency_ms { 1 }
  end
end
