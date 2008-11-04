class GcheckoutTransactions < ActiveRecord::Migration
  def self.up
  
    create_table "gcheckout_order_states", :force => true do |t|
      t.column "title", :string
    end

    create_table "gcheckout_transactions", :force => true do |t|
      t.column "user_id",                    :integer
      t.column "order_number",               :string
      t.column "order_total",                :float
      t.column "buyerid",                    :string
      t.column "serial_number",              :string
      t.column "currency",                   :string
      t.column "google_timestamp",           :datetime
      t.column "buyer_billing_email",        :string
      t.column "financial_order_state_id",   :integer
      t.column "fulfillment_order_state_id", :string
      t.column "created_at",                 :datetime
    end

    add_index "gcheckout_transactions", ["user_id"], :name => "index_gcheckout_transactions_on_user_id"
    add_index "gcheckout_transactions", ["financial_order_state_id"], :name => "index_gcheckout_transactions_on_financial_order_state_id"
    add_index "gcheckout_transactions", ["fulfillment_order_state_id"], :name => "index_gcheckout_transactions_on_fulfillment_order_state_id"
    add_index "gcheckout_transactions", ["order_number"], :name => "google_order_num_ind"  

  end

  def self.down
    drop_table :gcheckout_transactions
    drop_table :gcheckout_order_states
  end
end
