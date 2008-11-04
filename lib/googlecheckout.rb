# $Id: googlecheckout.rb 10170 2007-04-19 17:03:51Z kelyar $

require 'hmac-sha1'
require 'base64'

module ELRO
 module GoogleCheckout
  class SimpleCart

    def initialize(merchant_id, merchant_key, live=false)
      @merchant_id = merchant_id
      @merchant_key = merchant_key
      @items = []
      @live = live
      @submit_url = @live ? "https://checkout.google.com/cws/v2/Merchant/#{@merchant_id}/request" : 
        "https://sandbox.google.com/checkout/cws/v2/Merchant/#{@merchant_id}/checkout"
      @button_src = @live ? "http://checkout.google.com/buttons/checkout.gif?merchant_id=#{@merchant_id}" :
        "https://sandbox.google.com/checkout/buttons/checkout.gif?merchant_id=#{@merchant_id}"
      @button_src << "&style=white&w=180&h=46&variant=text&loc=en_US"
      # FIXME
      @continue_url = "https://localhost:3000/payment/status"
    end

    def additem(name,description,price,custom_item_id)
      @items << {:name=>name, :description => description, :merchant_item_id => custom_item_id, :price=>price}
    end
  
    def draw_button
      html = "<form method='post' action='#{@submit_url}' id='BB_BuyButtonForm' name='BB_BuyButtonForm'>"
      html << "<input type='hidden' name='cart' value='#{Base64.encode64(makecart).gsub("\n", '')}'/>"
      html << "<input type='hidden' name='signature' value='#{Base64.encode64(signature).gsub("\n", '')}'/>"
      html << "<input type='image' src='#{@button_src}'/>"
      html << "</form>"
    end

    def draw_decoded_cart
      @xml || makecart
    end

    protected

    def signature
      HMAC::SHA1.digest(@merchant_key, makecart)
    end

    # should use Builder
    def makecart
      xml = Builder::XmlMarkup.new
      xml.instruct!
      @xml = xml.tag!('checkout-shopping-cart', :xmlns => "http://checkout.google.com/schema/2") {
        xml.tag!("shopping-cart") {
          xml.items {
            @items.each { |item|
            xml.item {
              xml.tag!('item-name') {
                xml.text! item[:name].to_s
              }
              xml.tag!('item-description') {
                xml.text! item[:description].to_s
              }
              xml.tag!('unit-price',:currency => (item[:currency] || 'USD')) {
                xml.text! item[:price].to_s
              }
              xml.quantity {
                xml.text! item[:quantity] || "1"
              }
              xml.tag!('merchant-item-id') {
                xml.text! item[:merchant_item_id].to_s
              }
#              xml.tag!('merchant-private-item-data') {
#                xml.text! item[:merchant_item_id].to_s
#              }
            }
            }
          }
        }
        xml.tag!('checkout-flow-support') {
          xml.tag!('merchant-checkout-flow-support') {
            xml.tag!('continue-shopping-url') {
              xml.text! @continue_url.to_s
            }
          }
        }
      }
    end
  end
 end
end
