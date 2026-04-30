class TransactiontrialrawsController < ApplicationController
  
    skip_before_action :verify_authenticity_token
    
    def create
        # Read raw JSON body (important for webhooks)
        raw = request.body.read
        data = JSON.parse(raw) rescue params
    
        transactiontrialraw = Transactiontrialraw.new(
            rawpayload: data.to_s
        )
        if transactiontrialraw.save
            render json: { message: "Transaction trial raw created successfully" }, status: :created
        else
            render json: { errors: transactiontrialraw.errors.full_messages }, status: :unprocessable_entity
        end
    end

end

