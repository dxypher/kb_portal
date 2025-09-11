module AuthHelpers
  def sign_in(user)
    { "rack.session" => { user_id: user.id } }
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
