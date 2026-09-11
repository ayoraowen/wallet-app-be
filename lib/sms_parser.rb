# Classifies a finance SMS into a platform and a transaction type.
#
# Every pattern here was derived from real payloads captured in the
# transactiontrialraws table, not from documentation. Anything it does not
# recognise is returned as non-transactional rather than guessed at.
class SmsParser
  Result = Struct.new(
    :platform, :txn_type, :amount, :currency, :code,
    :counterparty, :balance_after, :transactional,
    keyword_init: true
  ) do
    def transactional? = transactional
  end

  # Sender IDs are matched after stripping punctuation, so "M-PESA", "MPESA"
  # and "M_PESA" all collapse to the same key. The old ALLOWED_SENDERS check
  # used a plain include? and silently rejected the hyphenated form.
  PLATFORMS = [
    [ /\A(mpesa|safaricom|saf)/, "mpesa" ],
    [ /stanchart|standardchartered/, "standard_chartered" ],
    [ /ncba/,                       "ncba" ],
    [ /stanbic/,                    "stanbic" ],
    [ /iandmbank|imbank/,           "i_and_m" ],
    [ /stima/,                      "stima_sacco" ],
    [ /vodacom/,                    "vodacom" ],
    [ /equity/,                     "equity" ],
    [ /kcb/,                        "kcb" ],
    [ /coop|cooperative/,           "co_op" ],
    [ /absa/,                       "absa" ],
    [ /dtb/,                        "dtb" ],
    [ /airtel/,                     "airtel_money" ]
  ].freeze

  AMOUNT    = /(?:ksh|kes|tsh|tzs)\.?\s?([\d,]+(?:\.\d{1,2})?)/i
  # No trailing \b: "Ksh100.00" has no word boundary between "h" and "1".
  CURRENCY  = /\b(ksh|kes|tsh|tzs)/i
  BALANCE   = /new\s+(?:m-?pesa\s+)?balance\s+is\s+(?:ksh|kes|tsh|tzs)\.?\s?([\d,]+(?:\.\d{1,2})?)/i
  CODE      = /\A([A-Z0-9]{8,12})\s+Confirmed/i

  class << self
    def call(sender:, message:)
      message = message.to_s
      platform = platform_for(sender, message)
      type = txn_type_for(platform, message)

      Result.new(
        platform: platform,
        txn_type: type,
        amount: type && extract(message, AMOUNT),
        currency: message[CURRENCY, 1]&.upcase,
        code: message[CODE, 1],
        counterparty: type && counterparty_for(type, message),
        balance_after: extract(message, BALANCE),
        transactional: !type.nil?
      )
    end

    private

    def platform_for(sender, message)
      key = sender.to_s.downcase.gsub(/[^a-z0-9]/, "")
      match = PLATFORMS.find { |pattern, _| key.match?(pattern) }
      return match.last if match
      # A bank can notify through a shortcode, so fall back to the body.
      return "mpesa" if message.match?(/m-?pesa/i)
      "other"
    end

    # Ordering matters: "sent to X for account Y" is a paybill and must be
    # tested before the bare "sent to".
    def txn_type_for(platform, message)
      msg = message.downcase
      case platform
      when "mpesa"
        return "received" if msg.match?(/you have received|confirmed.*receive\s+(?:ksh|tsh)/)
        return "withdraw" if msg.match?(/withdraw/)
        return "paybill"  if msg.match?(/sent to .* for account/)
        return "till"     if msg.match?(/paid to/)
        return "business" if msg.match?(/sent to business/)
        return "sent"     if msg.match?(/sent to/)
        nil
      else
        return "deposit"  if msg.match?(/was deposited to/)
        return "transfer" if msg.match?(/was transferred from|transfer of .* (?:has been processed|was successful)/)
        return "card"     if msg.match?(/made on card ending/)
        return "debit"    if msg.match?(/has been debited with/)
        return "credit"   if msg.match?(/has been credited with/)
        nil
      end
    end

    def counterparty_for(type, message)
      raw =
        case type
        when "received"  then message[/received\s+(?:ksh|kes|tsh|tzs)\.?\s?[\d,.]+\s+from\s+(.+?)\s+on\b/i, 1] ||
                              message[/\bfrom\s+(.+?)\s+New balance/i, 1]
        when "till"      then message[/paid to\s+(.+?)\s+on\b/i, 1]
        when "paybill"   then message[/sent to\s+(.+?)\s+for account/i, 1]
        when "business"  then message[/sent to business\s+(.+?)\s+on\b/i, 1]
        when "sent"      then message[/sent to\s+(.+?)\s+on\b/i, 1]
        when "card"      then message[/made on card ending\s+\d+\s+at\s+(.+?)\s+on\b/i, 1]
        when "deposit"   then message[/deposited to\s+(.+?)\.?\s*(?:for any|\z)/i, 1]
        when "transfer"  then message[/transfer of\s+(?:ksh|kes)\.?\s?[\d,.]+\s+to\s+(.+?)\s*(?:\(|bank ref|was |has been)/i, 1]
        end
      cleaned = raw.to_s.sub(/\s*\d{9,12}\s*\z/, "").sub(/[.,]\z/, "").strip
      cleaned.empty? ? nil : cleaned
    end

    def extract(message, pattern)
      found = message[pattern, 1]
      found && BigDecimal(found.delete(","))
    rescue ArgumentError
      nil
    end
  end
end
