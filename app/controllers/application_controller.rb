class ApplicationController < ActionController::Base#ActionController::API
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Authentication is on by default; endpoints that must stay public opt out
  # with `skip_before_action :authenticate_user!`. Failing closed like this
  # means a new controller is protected unless someone deliberately says
  # otherwise. /up is unaffected -- Rails::HealthController descends from
  # ActionController::Base, not from this class.
  before_action :authenticate_user!

  private

  attr_reader :current_user

  def authenticate_user!
    token = bearer_token
    claims = JsonWebToken.decode(token)
    @current_user = User.find(claims[:user_id])
  rescue JWT::DecodeError, ActiveRecord::RecordNotFound
    # JWT::ExpiredSignature subclasses JWT::DecodeError, so expiry lands here
    # too. RecordNotFound covers a validly-signed token for a deleted user.
    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def bearer_token
    request.headers["Authorization"].to_s.split(" ").last
  end

  # Shared shape for every response that hands a session to the client,
  # so signup and login can't drift apart. Slicing (rather than as_json)
  # keeps password_digest out by construction.
  def auth_response(user)
    {
      token: JsonWebToken.encode({ user_id: user.id }),
      user: user.slice(:id, :first_name, :last_name, :email)
    }
  end
end
