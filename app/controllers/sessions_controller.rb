class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token

  # POST /login
  def create
    user = User.find_by(email: session_params[:email])

    if user&.authenticate(session_params[:password])
      render json: {
        token: JsonWebToken.encode({ user_id: user.id }),
        user: user_payload(user)
      }, status: :ok
    else
      # Same response whether the email is unknown or the password is wrong,
      # so this can't be used to enumerate registered accounts.
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  private

  def session_params
    params.require(:session).permit(:email, :password)
  end

  def user_payload(user)
    user.slice(:id, :first_name, :last_name, :email)
  end
end
