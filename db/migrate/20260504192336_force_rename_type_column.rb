class ForceRenameTypeColumn < ActiveRecord::Migration[8.0]
  def change
    if column_exists?(:transactions, :type)
      rename_column :transactions, :type, :txn_type
    end
  end
end
