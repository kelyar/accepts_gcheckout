class GcheckoutTransaction < ActiveRecord::Base
  belongs_to :user
  belongs_to :financial_state, :class_name => "GcheckoutOrderState", :foreign_key => "financial_order_state_id"
  belongs_to :fulfillment_state, :class_name => "GcheckoutOrderState", :foreign_key => "fulfillment_order_state_id"

  after_save :notify_admin

  TO = %{test@example.com}
  FROM = %w{test@example.com}

  def notify_admin
    Notifier.deliver_admin_msg(
      TO,
      FROM, 
      "GCheckout transaction: #{order_total}",
      "#{order_number}: #{buyer_billing_email} (#{user_id}): +#{order_total} #{currency}"
    ) if financial_state.charged? && credited_at.nil?
  end
end
