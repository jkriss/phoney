require 'rubygems'
require 'sinatra'
require 'twilio'
require 'sequel'
require 'sinatra/sequel'
require 'haml'

Twilio.connect(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])

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
  @recordings = database[:recordings]
  haml :index
end

post '/voice' do
  content_type :xml
  last_recording = database[:recordings].order(:created_at).last
  verb = Twilio::Verb.new { |v|
    v.say "Welcome to Die Ull A Story"
    if last_recording
      v.play last_recording[:url]
      v.say "At the beep, record the next line. Press star when you're finished"
    else
      v.say "You get to make the first recording."
      v.say "At the beep, record the next line. Press star when you're finished"
    end

    action = "recording"
    action += "?in_reply_to=#{last_recording[:id]}" if last_recording
    v.record :finishOnKey => '*', :action => action
    v.hangup
  }
  verb.response
end

post '/recording' do
  if params['Duration'].to_i > 3
    database[:recordings].insert( :url => params['RecordingUrl'], :created_at => Time.now, :zip_code => params['CallerZip'], :previous_recording_id => params[:in_reply_to])
  end
  content_type :xml
  verb = Twilio::Verb.new { |v|
    v.say "Thank you"
    v.hangup
  }
  verb.response
end