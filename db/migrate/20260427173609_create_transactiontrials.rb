class CreateTransactiontrials < ActiveRecord::Migration[8.0]
  def change
    create_table :transactiontrials do |t|
      t.string :smsmsg

      t.timestamps
    end
  end
end
