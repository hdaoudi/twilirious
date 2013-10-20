require "twilio.rb"
require 'xmlsimple'
require 'twitter'
require 'time'

# Twilio Settings
ACCOUNT_SID   = ''
ACCOUNT_TOKEN = ''
API_VERSION   = '2010-04-01'
BASE_URL      = "http://twilirious.com"
CALLER_ID     = '4158952220'

class MessageController < ApplicationController
  protect_from_forgery :only => [:delete]
  before_filter :load_twitter

  def index
    # Display tweets in the view
  end

  def twupdate
    # Parameters sent to Twilio REST API
    parameters = { 'Url' => BASE_URL + '/message/receiver.xml' }

    # Initiate and initialize
    begin
      account = Twilio::RestAccount.new(ACCOUNT_SID, ACCOUNT_TOKEN)
      retrieve = account.request("/#{API_VERSION}/Accounts/#{ACCOUNT_SID}/SMS/Messages", 'GET', parameters)
      retrieve.error! unless retrieve.kind_of? Net::HTTPSuccess      
    rescue StandardError => bang
      redirect_to(root_url, :notice => "Error: #{ bang }")
      return
    end

    #Establish key variables
    string      = retrieve.body
    hash        = XmlSimple.xml_in(string)
    @messages   = Hashie::Mash.new(hash["SMSMessages"][0])
    @last_msg   = @messages.SMSMessage.first.Body.join.to_s.gsub("&#0;", "@")
    
    
    #Identify the number of the last sent message
    #Counts the messages that: (1) have a match for that number and (2) that were sent within 3600 seconds (i.e. 1Hours)
    @last_from = @messages.SMSMessage.first.From.to_s
    @i = 0
    
    @messages.SMSMessage.each do |msg|
    message_time_ago = Time.now - Time.parse(msg.DateCreated.to_s)
      if @last_from == msg.From.to_s && message_time_ago.to_i < 3600
        @i += 1
      end
    end
    
    @client = Twitter.user
    @last_tweet = Twitter.user_timeline.first.text
    
    unless @last_msg == @last_tweet || @i > 3
      Twitter.update(@last_msg)
    end
  end
  
  def test
  end

  private
  def load_twitter
    Twitter.configure do |config|
      config.consumer_key       = ""
      config.consumer_secret    = ""
      config.oauth_token        = ""
      config.oauth_token_secret = ""
    end
  end
end
