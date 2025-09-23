class HealthController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :require_login, raise: false rescue nil

  def show
    render plain: "ok"
  end
end
