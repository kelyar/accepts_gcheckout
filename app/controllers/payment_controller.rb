# $Id: payment_controller.rb 8036 2006-12-25 10:19:44Z kelyar $

require "#{RAILS_ROOT}/lib/can_accept_google_checkout.rb"

class PaymentController < ApplicationController
  
  G_MERCHANTID = "PUT_HERE_YOUR_MERCHANT_ID"  
  G_MERCHANTKEY = "PUT_HERE_YOUR_MERCHANT_KEY" 
  G_LIVE = false
  include CanAcceptGoogleCheckout

  ssl_allowed  :status, :g_checkout_callback, :g_server2server
#  before_filter :loginrequired, :only => [:status, :g_server2server]

  def hello
    render :text => post_request("<hello/>").body
  end

  def status
    if request.xhr?
      if params[:txnid] && User.current_user
        tr = GcheckoutTransaction.find_by_order_number_and_user_id(params[:txnid], User.current_user.id)
        if tr
          @status = tr.financial_state.to_s
          @txnid = tr.order_number
          @order_total = tr.order_total
          render :partial => "status_progress" and return
        end
      end
      render :nothing => true, :status => 404 and return false
    end

    if User.current_user
      tr = params.include?(:txnid) ?
        GcheckoutTransaction.find_by_order_number_and_user_id(params[:txnid], User.current_user.id) :
        tr = User.current_user.gcheckout_transactions.first 

      unless params.include?(:txnid)
        redirect_to :txnid => tr.order_number and return if tr
      end
      flash.now[:warning] = "Wrong transaction" if tr.nil?
      if tr && tr.financial_state.charged?
        flash[:confirm] = "Congratulations, #{tr.order_total} was successfully added to your account!"
        redirect_to "/user/account" and return
      elsif tr
        case tr.financial_state.title 
        when "CANCELLED_BY_GOOGLE": flash.now[:warning] = "Google responded with CANCELLED BY GOOGLE status. We are unable to credit your account at this time. Please try again or use any other method of payment to add funds."
        when "PAYMENT_DECLINED": flash.now[:warning] = "Google responded with PAYMENT DECLINED status. We are unable to credit your account at this time. Please try again or use any other method of payment to add funds."
        when "CANCELLED": flash.now[:warning] = "Google responded with CANCELLED status. We are unable to credit your account at this time. Please try again or use any other method of payment to add funds."
        end
        @status = tr.financial_state.to_s
        @txnid = tr.order_number
      end
    end
    @page_title = "Payment Status"
  end

  def g_server2server
    sum = params[:info][:amount].to_f rescue 5.0
    cart = ELRO::GoogleCheckout::SimpleCart.new(G_MERCHANTID, G_MERCHANTKEY)
    cart.additem("Add money", "Add money to your account (#{User.current_user.email})", 
      sum, User.current_user.id)
    @decoded_cart = cart.draw_decoded_cart
    checkout(@decoded_cart)
  end

  def g_charge_amount_notification(opts)

    tr = GcheckoutTransaction.find_by_order_number(opts["google-order-number"], :include => :user)
    if tr && tr.user
      options = { :value => opts['total-charge-amount'], 
        :method=>"gcheckout",
        :data => tr[:order_number],   
        :x_forwarded_for=> request.remote_ip  # useless - it's google ip
      }

      tr.user.credit_money(options) if tr.credited_at.nil? or tr.credited_at.to_i.zero?
      tr.update_attribute(:credited_at, Time.now)
      deliver(opts["google-order-number"])
    end
  end

end
