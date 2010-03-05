require 'rubygems'
require 'sinatra'
require 'twilio'
require 'logger'
require 'sequel'
require 'sinatra/sequel'

Twilio.connect(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])
@@logger = Logger.new('tmp/development.log')

set :database, ENV['DATABASE_URL'] || 'sqlite://my.db'

migration "create recordings table" do
  database.create_table :recordings do
    primary_key :id
    String :url
    String :zip_code
    Time :created_at
  end
end

migration "add previous recording link" do
  database.alter_table :recordings do
    add_column :previous_recording_id, :varchar
  end
end

get '/' do
  h = "<h1>#{database[:recordings].count} recordings</h1>"
  h += "<ul>"
  database[:recordings].each do |r|
    h += "<li>From #{r[:zip_code]} (or thereabouts) at #{r[:created_at]}: <a href=\"#{r[:url]}\">listen</a></a>"
  end
  h += "</ul>"
  h
end

post '/voice' do
  content_type :xml
  last_recording = database[:recordings].order(:created_at).last
  verb = Twilio::Verb.new { |v|
    v.say "Welcome to Die Ull A Story"
    v.play last_recording[:url]
    v.say "At the beep, record the next line. Press star when you're finished"
    v.record :finishOnKey => '*', :action => "recording?in_reply_to=#{last_recording[:id]}"
    v.hangup
  }
  verb.response
end

post '/recording' do
  @@logger.info params['RecordingUrl']  
  database[:recordings].insert( :url => params['RecordingUrl'], :created_at => Time.now, :zip_code => params['CallerZip'], :previous_recording_id => params[:in_reply_to])
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