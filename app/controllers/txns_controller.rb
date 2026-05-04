class TxnsController < ApplicationController
    skip_before_action :verify_authenticity_token

  # Allowed senders (can be full numbers or partial matches)
  ALLOWED_SENDERS = ["6505551212", "SAFARICOM", "MPESA"].freeze

  # Keywords to look for inside message
#   KEYWORDS = %w[payment token meter units success failed].freeze #deprecated

  def create
  raw = request.body.read

  begin
    data = JSON.parse(raw).deep_stringify_keys
  rescue JSON::ParserError
    return render json: { error: "Invalid JSON" }, status: :bad_request
  end

  sender  = data.dig("payload", "sender")&.downcase
  message = data.dig("payload", "message")

  return render json: { message: "Ignored: sender not allowed" }, status: :ok unless sender_matches?(sender)

  enriched_data = enrich_payload(data)

  return render json: { message: "Ignored: not a supported transaction type" }, status: :ok unless enriched_data

  transaction = Transaction.new(
    rawpayload: enriched_data.to_s,
    sender: sender,
    message: message,
    event: data["event"],
    amount: enriched_data["amount"],#had to be enriched from extractioN from message
    transaction_code: enriched_data["transaction_code"],#had to be enriched from extractioN from message
    txn_type: enriched_data["type"],#had to be enriched from extractioN from message
    received_at_time_trial: data.dig("payload", "receivedAt"),
    cparty_name: data.dig("payload", "sender"),
    cparty_phn_no: data.dig("payload", "phoneNumber")
  )

  if transaction.save
    render json: { message: "Saved successfully" }, status: :created
  else
    render json: { errors: transaction.errors.full_messages }, status: :unprocessable_entity
  end
end

  private
  def detect_transaction_type(message)
    # return nil unless message
    # msg = message.downcase
    
    # if msg.include?("paid to")
    #     "till"
    # elsif msg.include?("sent to") && msg.include?("for account")
    #     "paybill"
    # else
    #     nil
    # end
    return nil unless message

  msg = message.downcase

  case msg
  when /paid to/
    "till"
  when /sent to .* for account/
    "paybill"
  else
    nil
  end
end#not sure why its not formatting level properly

def extract_details(message)
  return {} unless message

  {
    amount: extract_amount(message),
    transaction_code: extract_transaction_code(message)
  }
end

def extract_amount(message)
  match = message.match(/Ksh\s?([\d,]+\.\d{2})/i)
  match ? match[1].gsub(",", "").to_f : nil
end

def extract_transaction_code(message)
  match = message.match(/^([A-Z0-9]+)/)
  match ? match[1] : nil
end
  
  

  def sender_matches?(sender)
    return false unless sender

    ALLOWED_SENDERS.any? do |allowed|
      sender.include?(allowed.downcase)
    end
  end

  def enrich_payload(data)
#     message = data.dig("payload", "message")

#   tx_type = detect_transaction_type(message)

#   return nil unless tx_type # ignore if not recognized

#   data.merge(
#     "processed_at" => Time.current,
#     "type" => tx_type
#   )
#   end
message = data.dig("payload", "message")

  tx_type = detect_transaction_type(message)
  return nil unless tx_type

  details = extract_details(message)

  data.merge(
    "processed_at" => Time.current,
    "txn_type" => tx_type,
    "amount" => details[:amount],
    "transaction_code" => details[:transaction_code]
  )
end
end
