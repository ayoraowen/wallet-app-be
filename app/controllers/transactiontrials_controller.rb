class TransactiontrialsController < ApplicationController
skip_before_action :verify_authenticity_token
def create
        transactiontrial = Transactiontrial.new(transactiontrial_params)
        if transactiontrial.save
            render json: { message: "Transaction trial created successfully" }, status: :created
        else
            render json: { errors: transactiontrial.errors.full_messages }, status: :unprocessable_entity
        end
    end

    private
    # def transactiontrial_params
    #     params[:message]
    # end
    def transactiontrial_params
        params.require(:transactiontrial).permit(:smsmsg)
    end




end