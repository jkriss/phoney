require 'rubygems'
require 'sinatra'
require 'twilio'
require 'sequel'
require 'sinatra/sequel'
require 'haml'
require 'builder'

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

get '/feed' do
  @recordings = database[:recordings]
  content_type 'application/xml', :charset => 'utf-8'
  builder do |xml|
    xml.instruct! :xml, :version => '1.0'
    xml.rss :version => "2.0" do
      xml.channel do
        xml.title "Phone Tag"
        xml.description "Messages from strangers."
        xml.link "http://phonetag.heroku.com"
        
        @recordings.each do |r|
          xml.item do
            xml.title "Message from #{r[:zip_code]}"
            xml.link r[:url]
            xml.description "<p>#{r[:zip_code]} (or thereabouts) on #{r[:created_at].strftime('%b %d at %I:%M %p')}</p><p> <a href=\"#{r[:url]}.mp3\">> listen</a></p>"
            xml.pubDate Time.parse(r[:created_at].to_s).rfc822()
            xml.guid "http://phonetag.heroku.com/recordings/#{r[:id]}"
          end
        end
      end
    end
  end
end

post '/voice' do
  content_type :xml
  last_recording = database[:recordings].order(:created_at).last
  verb = Twilio::Verb.new { |v|
    v.say "Welcome to Phone Tag"
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