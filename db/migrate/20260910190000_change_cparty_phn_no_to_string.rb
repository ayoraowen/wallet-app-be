class ChangeCpartyPhnNoToString < ActiveRecord::Migration[8.0]
  # cparty_phn_no was an int4 (max 2,147,483,647). A Kenyan MSISDN such as
  # 254700000000 overflows it, so TxnsController#create raised
  # ActiveModel::RangeError and returned 500 for any SMS carrying a phone
  # number -- the device could not store a real transaction at all.
  #
  # String rather than bigint: a phone number is an identifier, not a quantity.
  # Nothing arithmetic is ever done with it, and the integer form silently
  # destroys a leading 0 (0700...) and cannot hold a leading +.
  def up
    change_column :transactions, :cparty_phn_no, :string
  end

  def down
    change_column :transactions, :cparty_phn_no, :integer,
                  using: "cparty_phn_no::integer"
  end
end
