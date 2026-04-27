# class TransactiontrialsController < ApplicationController
# skip_before_action :verify_authenticity_token
# def create
#         transactiontrial = Transactiontrial.new(transactiontrial_params)
#         if transactiontrial.save
#             render json: { message: "Transaction trial created successfully" }, status: :created
#         else
#             render json: { errors: transactiontrial.errors.full_messages }, status: :unprocessable_entity
#         end
#     end

#     private
#     # def transactiontrial_params
#     #     params[:message]
#     # end
#     def transactiontrial_params
#         params.require(:transactiontrial).permit(:smsmsg)
#     end




# end

#REFACTORING AS SUGGESTED BY CHATGPT TO HANDLE RAW JSON BODY FOR WEBHOOKS
class TransactiontrialsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    # Read raw JSON body (important for webhooks)
    raw = request.body.read
    data = JSON.parse(raw) rescue params

    transactiontrial = Transactiontrial.new(
      smsmsg: data["smsmsg"] || data.dig("transactiontrial", "smsmsg")
    )

    if transactiontrial.save
      render json: { message: "Transaction trial created successfully" }, status: :created
    else
      render json: { errors: transactiontrial.errors.full_messages }, status: :unprocessable_entity
    end
  end
end