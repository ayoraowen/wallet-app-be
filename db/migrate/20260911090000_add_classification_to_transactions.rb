class AddClassificationToTransactions < ActiveRecord::Migration[8.0]
  # All three values are already present in the SMS text and were being
  # discarded by the old ingest:
  #
  #   platform       -- which financial service the message came from, so the
  #                     dashboard can group M-Pesa vs bank vs sacco activity
  #   currency       -- the captured corpus contains both Kenyan (Ksh/KES) and
  #                     Tanzanian (Tsh) messages; summing them blind is wrong
  #   balance_after  -- "New M-PESA balance is Ksh442.28" was parsed away, and
  #                     the API has been serving a hardcoded null in its place
  #
  # Additive and nullable, so the currently deployed app is unaffected until it
  # is redeployed -- old code simply ignores columns it does not know about.
  def change
    add_column :transactions, :platform, :string
    add_column :transactions, :currency, :string
    add_column :transactions, :balance_after, :decimal

    add_index :transactions, :platform
  end
end
