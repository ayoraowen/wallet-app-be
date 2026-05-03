class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.string :rawpayload
      t.string :type
      t.decimal :amount
      t.string :transaction_code
      t.string :received_at_time_trial
      t.integer :cparty_phn_no
      t.string :cparty_name

      t.timestamps
    end
  end
end
