class MeController < ApplicationController
  # GET /me
  # Authenticated by the inherited before_action. Lets the frontend check a
  # token it restored from localStorage instead of trusting it until the
  # first real request fails.
  def show
    render json: { user: current_user.slice(:id, :first_name, :last_name, :email) }
  end
end
