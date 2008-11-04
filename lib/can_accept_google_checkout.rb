# $Id: can_accept_google_checkout.rb 10170 2007-04-19 17:03:51Z kelyar $

require "net/https"

module CanAcceptGoogleCheckout

  # API callback URL
  # https://sandbox.google.com/checkout/sell/settings?section=Integration

  def self.included(base)
    @merchant_id = base::G_MERCHANTID
    @merchant_key = base::G_MERCHANTKEY
    @google_service_url= base::G_LIVE ? "https://checkout.google.com/cws/v2/Merchant/#{base::G_MERCHANTID}/request" :
      "https://sandbox.google.com/checkout/cws/v2/Merchant/#{base::G_MERCHANTID}/request"
    @merchant_url = base::G_LIVE ? "https://checkout.google.com/cws/v2/Merchant/#{base::G_MERCHANTID}/merchantCheckout" : 
      "https://sandbox.google.com/checkout/cws/v2/Merchant/#{base::G_MERCHANTID}/merchantCheckout"
  end

  def g_checkout_callback
    self.process_google_request(params)

=begin
    Notifier.deliver_admin_msg(
      %w{kelyar@ua.elro.com},
      "gcheckout-notifier@payplay.fm", 
      "Google Checkout: notification",
      params.inspect
    )
=end
    headers["Content-type"] = "text/xml"
    render :text=>'<?xml version="1.0" encoding="UTF-8"?><notification-acknowledgment xmlns="http://checkout.google.com/schema/2"/>'
  end  

  def charge_order(orderid,amount)

    xml = '<?xml version="1.0" encoding="UTF-8"?><charge-order xmlns="http://checkout.google.com/schema/2" google-order-number="'+orderid.to_s+'"><amount currency="USD">'+amount.to_s+'</amount></charge-order>'
    self.post_request(xml, false)
  end

  def process_google_request(opts)
    case opts["_type"]
    when "new-order-notification" then
      transaction = GcheckoutTransaction.create(:user_id => opts["shopping-cart.items.item-1.merchant-item-id"],
        :order_number => opts["google-order-number"],
        :order_total => opts["order-total"],
        :buyerid => opts["buyer-id"],
        :serial_number => opts["serial-number"],
        :currency => opts["order-total.currency"],
        :google_timestamp => opts["timestamp"].to_time,
        :buyer_billing_email => opts["buyer-billing-address.email"],
        :financial_order_state_id => GcheckoutOrderState.find_or_create_by_title(opts["financial-order-state"]).id,
        :fulfillment_order_state_id => GcheckoutOrderState.find_or_create_by_title(opts["fulfillment-order-state"]).id
      )

    when "order-state-change-notification" then
      tr = GcheckoutTransaction.find_or_create_by_order_number(opts["google-order-number"])
      tr.update_attribute(:financial_order_state_id, 
        GcheckoutOrderState.find_or_create_by_title(opts["new-financial-order-state"]).id)
      tr.update_attribute(:fulfillment_order_state_id, 
        GcheckoutOrderState.find_or_create_by_title(opts["new-fulfillment-order-state"]).id)
#      charge_order(tr["order_number"], tr["order_total"]) if tr.financial_state.chargeable? && opts["previous-financial-order-state"].eql?("REVIEWING")

    when "risk-information-notification" then
      tr = GcheckoutTransaction.find_by_order_number(opts["google-order-number"])
    when "charge-amount-notification" then
    end
    if opts["_type"]
      method_name = method_name(opts["_type"])
      send(method_name, opts) if self.public_methods.include?(method_name)
    end
  end

#  protected
  def method_name(type)
    "g_"+type.downcase.gsub("-","_") rescue nil
  end
  
  def post_request(content, knock_merchant_url = true)
    unless instance_values.include?("google_service_url")
      self.copy_instance_variables_from(CanAcceptGoogleCheckout)
    end
    uri = knock_merchant_url ? URI.parse(@merchant_url) : URI.parse(self.instance_values["google_service_url"])
    request_path = uri.path

    request = Net::HTTP::Post.new(request_path)
    request['Content-Length'] = "#{content.size}"

    http = Net::HTTP.new(uri.host, uri.port)
    http.verify_mode    = OpenSSL::SSL::VERIFY_NONE unless @ssl_strict
    http.use_ssl        = true
    http.start do |http|
      request.basic_auth @merchant_id, @merchant_key
      request = http.request(request, content)
    end
  end
  
  def checkout(content)
    resp = post_request(content)
    if resp.code.to_i.eql?(200)
      url = resp.body.scan(/<redirect-url>(.*)<\/redirect-url>/)
      redirect_to url.to_s.gsub("&amp;","&") and return unless url.empty?
    end
    render :text => resp.body.inspect
  end

  def deliver(orderid)
    xml='<?xml version="1.0" encoding="UTF-8"?><deliver-order xmlns="http://checkout.google.com/schema/2" google-order-number="'+orderid+'" />'
    post_request(xml, knock_merchant_url=false)
  end
end
