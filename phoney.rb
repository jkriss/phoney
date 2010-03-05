require 'rubygems'
require 'sinatra'
require 'twilio'
require 'logger'
require 'sequel'

Twilio.connect(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])
@@logger = Logger.new('development.log')

DB = Sequel.connect(ENV['DATABASE_URL'] || 'sqlite://my.db')

DB.create_table? :recordings do
  primary_key :id
  String :url
  String :zip_code
  Time :created_at
end

get '/' do
  h = "<h1>#{DB[:recordings].count} recordings</h1>"
  h += "<ul>"
  DB[:recordings].each do |r|
    h += "<li>From #{r[:zip_code]} (or thereabouts) at #{r[:created_at]}: <a href=\"#{r[:url]}\">listen</a></a>"
  end
  h += "</ul>"
  h
end

post '/voice' do
  content_type :xml
  verb = Twilio::Verb.new { |v|
    v.say "Welcome to Die Ull A Story"
    v.say "At the beep, record the next line. Press star when you're finished"
    v.record :finishOnKey => '*', :action => 'recording'
    v.hangup
  }
  verb.response
end

post '/recording' do
  @@logger.info params['RecordingUrl']
  
  DB[:recordings].insert( :url => params['RecordingUrl'], :created_at => Time.now, :zip_code => params['CallerZip'])
  # recording = request.body.read
  # @@logger.info recording.inspect
  # @@logger.info recording.class
  content_type :xml
  verb = Twilio::Verb.new { |v|
    v.say "Thank you"
    v.hangup
  }
  verb.response
end