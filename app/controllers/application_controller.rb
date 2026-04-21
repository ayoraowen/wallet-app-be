class ApplicationController < ActionController::Base#ActionController::API
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  #implementing authentication with JWT
  # before_action :authenticate_user

  # attr_reader :current_user, :current_user_id
  # private
  # def authenticate_user
  #   auth_header = request.headers['Authorization']
  #   token = auth_header.split(' ').last if auth_header

  #   begin
  #     decoded_token = JWT.decode(token, Rails.application.secrets.secret_key_base)[0]
  #     @current_user_id = decoded_token['user_id']
  #     @current_user = User.find(@current_user_id)
  #   rescue JWT::DecodeError
  #     render json: { error: 'Unauthorized' }, status: :unauthorized
  #   end





  


  
  



  


end
