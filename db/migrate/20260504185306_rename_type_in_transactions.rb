class RenameTypeInTransactions < ActiveRecord::Migration[8.0]
  def change
    rename_column :transactions, :type, :txn_type
  end
end
