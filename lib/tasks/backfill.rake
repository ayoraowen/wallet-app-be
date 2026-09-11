namespace :transactions do
  desc "Re-classify captured SMS in transactiontrialraws into transactions (idempotent)"
  task backfill: :environment do
    dry_run = ENV["DRY_RUN"] == "1"
    created = 0
    skipped_existing = 0
    skipped_non_txn = 0

    Transactiontrialraw.find_each do |raw|
      body = raw.rawpayload.to_s
      sender  = body[/"sender"\s*=>\s*"([^"]*)"/, 1]
      message = body[/"message"\s*=>\s*"(.*?)", "receivedAt"/m, 1] ||
                body[/"message"\s*=>\s*"([^"]*)"/, 1]

      parsed = SmsParser.call(sender: sender, message: message)
      unless parsed.transactional?
        skipped_non_txn += 1
        next
      end

      # Idempotency: an M-Pesa code uniquely identifies a transaction. Bank
      # messages carry no such code, so fall back to the exact raw payload,
      # which is unique per captured SMS.
      already =
        if parsed.code.present?
          Transaction.exists?(transaction_code: parsed.code)
        else
          Transaction.exists?(rawpayload: body)
        end

      if already
        skipped_existing += 1
        next
      end

      received_at = body[/"receivedAt"\s*=>\s*"([^"]*)"/, 1]
      phone       = body[/"phoneNumber"\s*=>\s*"([^"]*)"/, 1]

      unless dry_run
        Transaction.create!(
          rawpayload: body,
          platform: parsed.platform,
          txn_type: parsed.txn_type,
          amount: parsed.amount,
          currency: parsed.currency,
          balance_after: parsed.balance_after,
          transaction_code: parsed.code,
          cparty_name: parsed.counterparty,
          cparty_phn_no: phone,
          received_at_time_trial: received_at
        )
      end
      created += 1
    end

    puts "  #{dry_run ? '[DRY RUN] would create' : 'created'}: #{created}"
    puts "  skipped, already present : #{skipped_existing}"
    puts "  skipped, not a transaction: #{skipped_non_txn}"
    puts "  transactions total now   : #{Transaction.count}" unless dry_run
  end
end

namespace :transactions do
  desc "Classify pre-parser rows in place from their stored rawpayload (idempotent)"
  task classify_existing: :environment do
    dry_run = ENV["DRY_RUN"] == "1"
    updated = 0
    unclassifiable = 0

    Transaction.where(platform: nil).find_each do |t|
      body = t.rawpayload.to_s
      sender  = body[/"sender"\s*=>\s*"([^"]*)"/, 1]
      message = body[/"message"\s*=>\s*"(.*?)", "receivedAt"/m, 1] ||
                body[/"message"\s*=>\s*"([^"]*)"/, 1]

      parsed = SmsParser.call(sender: sender, message: message)
      unless parsed.transactional?
        unclassifiable += 1
        next
      end

      unless dry_run
        # Only fill gaps -- never overwrite a value the row already has.
        t.update!(
          platform: parsed.platform,
          currency: t.currency.presence || parsed.currency,
          balance_after: t.balance_after || parsed.balance_after,
          cparty_name: t.cparty_name.presence || parsed.counterparty
        )
      end
      updated += 1
    end

    puts "  #{dry_run ? '[DRY RUN] would update' : 'updated'}: #{updated}"
    puts "  left unclassified        : #{unclassifiable}"
    puts "  still nil platform       : #{Transaction.where(platform: nil).count}" unless dry_run
  end
end
