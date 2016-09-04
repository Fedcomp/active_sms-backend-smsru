require "net/http"
require "active_sms"
require "active_sms/backend/smsru/version"

class ActiveSMS::Backend::Smsru < ActiveSMS::Backend::Base
  API_URL = "http://sms.ru/sms/send".freeze

  def initialize(params = {})
    @api_id = params.delete(:api_id)
    validate_api_id
  end

  def send_sms(phone, sms_text)
    response = request_api(to: phone, text: sms_text)
    data = parse(response)

    case data[:status]
    when 100
      respond_with_status :success
    else
      respond_with_status "unknown_status_#{data[:status]}".to_sym
    end
  end

  private

  def validate_api_id
    raise ArgumentError, "Your api_id is not set" if @api_id.nil?

    unless @api_id =~ /\w{8}-\w{4}-\w{4}-\w{4}-\w{12}/
      raise ArgumentError, "Your api_id has invalid format"
    end
  end

  def request_api(params = {})
    params = params.merge(api_id: @api_id)
    Net::HTTP.post_form(URI.parse(API_URL), params).body
  end

  def parse(response)
    status, sms_id, balance = response.strip.split("\n")
    status = status.to_i
    balance = balance.split("=").last.to_d if balance

    response = { status: status }
    response[:balance] = balance if balance
    response[:sms_id]  = sms_id if sms_id
    response
  end
end