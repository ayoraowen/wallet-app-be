class CreateTransactiontrialraws < ActiveRecord::Migration[8.0]
  def change
    create_table :transactiontrialraws do |t|
      t.string :rawpayload

      t.timestamps
    end
  end
end
