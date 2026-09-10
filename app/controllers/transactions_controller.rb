class TransactionsController < ApplicationController
  DEFAULT_PER_PAGE = 100
  MAX_PER_PAGE = 200

  # GET /transactions
  def index
    scope = Transaction.order(created_at: :desc, id: :desc)
    total = scope.count
    records = scope.limit(per_page).offset((page - 1) * per_page)

    render json: {
      transactions: records.map { |t| serialize(t) },
      meta: { page: page, per_page: per_page, total: total }
    }
  end

  private

  def page
    @page ||= [ params[:page].to_i, 1 ].max
  end

  def per_page
    @per_page ||= begin
      requested = params[:per_page].to_i
      requested = DEFAULT_PER_PAGE if requested <= 0
      [ requested, MAX_PER_PAGE ].min
    end
  end

  # The client and the table disagree on the name of nearly every field, so the
  # mapping is explicit here rather than left to a bare `render json: record`.
  # Rendering the raw row would still parse on the client -- its fallback chains
  # don't list these column names, so every row would quietly come back as type
  # "received" with amount 0 and no counterparty, and look like it worked.
  def serialize(transaction)
    {
      id: transaction.id,
      mpesa_code: transaction.transaction_code,
      type: transaction.txn_type,
      # BigDecimal serialises as a JSON string to preserve precision; these are
      # display amounts, so send a number and skip the client-side coercion.
      amount: transaction.amount&.to_f,
      counterparty_name: transaction.cparty_name,
      counterparty_phone: transaction.cparty_phn_no&.to_s,
      # No such column yet -- explicit null beats omitting the key, so the
      # client sees "unknown" rather than a missing field.
      balance_after: nil,
      transaction_time: transaction_time_for(transaction),
      raw_text: transaction.rawpayload
    }
  end

  # received_at_time_trial is a free-text string straight off the device, so it
  # can be unparseable or absent. The dashboard sorts and charts on this, so it
  # falls back to created_at, which is always a real timestamp.
  def transaction_time_for(transaction)
    parsed =
      begin
        Time.zone.parse(transaction.received_at_time_trial.to_s)
      rescue ArgumentError, TypeError
        nil
      end

    (parsed || transaction.created_at).iso8601
  end
end
