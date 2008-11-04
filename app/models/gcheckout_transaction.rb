class GcheckoutTransaction < ActiveRecord::Base
  belongs_to :user
  belongs_to :financial_state, :class_name => "GcheckoutOrderState", :foreign_key => "financial_order_state_id"
  belongs_to :fulfillment_state, :class_name => "GcheckoutOrderState", :foreign_key => "fulfillment_order_state_id"

  after_save :notify_admin

  def notify_admin
    Notifier.deliver_admin_msg(
      %w{kelyar@ua.elro.com},
      "gcheckout-notifier@payplay.fm", 
      "GCheckout transaction: #{self.order_total}",
      "#{self.order_number}: #{self.buyer_billing_email} (#{self.user_id}) just credited #{self.order_total} #{self.currency}"
    ) if self.financial_state.charged? && self.credited_at.nil?
  end
end
