class TxnsController < ApplicationController
  # Device SMS ingest: no user context yet, deferred to the scoping slice.
  skip_before_action :authenticate_user!

  # POST /api/txns/device
  def create
    data = parse_body
    return render json: { error: "Invalid JSON" }, status: :bad_request if data.nil?

    payload = data["payload"] || {}
    parsed = SmsParser.call(sender: payload["sender"], message: payload["message"])

    # An SMS that isn't a transaction is a normal, expected outcome -- most of
    # what a phone receives is marketing. It is reported as 202 Accepted rather
    # than the old 200, so "we stored this" and "we deliberately skipped this"
    # are distinguishable by the device. Previously both were 200 and real
    # transactions were being dropped with no signal at all.
    unless parsed.transactional?
      return render json: {
        status: "ignored",
        reason: "not a recognised transaction",
        platform: parsed.platform
      }, status: :accepted
    end

    transaction = Transaction.new(
      rawpayload: data.to_s,
      platform: parsed.platform,
      txn_type: parsed.txn_type,
      amount: parsed.amount,
      currency: parsed.currency,
      balance_after: parsed.balance_after,
      transaction_code: parsed.code,
      cparty_name: parsed.counterparty,
      cparty_phn_no: payload["phoneNumber"],
      received_at_time_trial: payload["receivedAt"]
    )

    if transaction.save
      render json: { status: "saved", id: transaction.id, platform: parsed.platform,
                     txn_type: parsed.txn_type }, status: :created
    else
      render json: { errors: transaction.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  # Webhooks post a raw JSON body, so read it directly rather than relying on
  # Rails' param wrapping.
  def parse_body
    JSON.parse(request.body.read).deep_stringify_keys
  rescue JSON::ParserError
    nil
  end
end
