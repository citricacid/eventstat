# encoding: utf-8

require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'sinatra/flash'
require "sinatra/reloader" if development?
require 'tilt/erb' if development?

require 'date'

require_relative 'models'
require_relative 'settings'

ActiveRecord::Base.establish_connection(Settings::DBWEB)

register Sinatra::Reloader if development?
set :bind, '0.0.0.0' if development?

set :server, %w[thin webrick]
enable :sessions
enable :show_exceptions

set :sessions, key: Settings::SESSION_KEY, secret: Settings::SECRET



# -------------------------

def require_logged_in
  #redirect('/login') unless is_authenticated?
end

def is_authenticated?
  return session[:user_id]
end

def is_admin?
  session[:admin]
end

def protected!
  halt 401, "You are not authorized to see this page!" unless admin?
end

# -------------------------


get '/' do
  redirect('/manage_events')
end

get '/login' do
  erb :login
end

get '/logout' do
  session.clear
  redirect('/')
end


post '/sessions' do
  if params["pw"] == Settings::PW
    session[:user_id] = params["user_id"]
  end

  if params["pw"] == Settings::PWADMIN
    session[:user_id] = params["user_id"]
    session[:admin] = params["user_id"]
  end

  redirect('/manage_schedules')
end

get '/manage_events' do
  require_logged_in
  desc = ''
  erb :manage_events, :locals => {branches: Branch.all, genres: Genre.all, categories: Category.all, edit: false }
end



get '/view_events' do
  require_logged_in

  erb :view_events, :locals => {events: Event.all, branches: Branch.all}
end


get '/edit_event/:event_id' do
  require_logged_in

  event_id = params['event_id']


  erb :manage_events, :locals => {branches: Branch.all, genres: Genre.all, categories: Category.all, event: Event.find(event_id), edit: true }
end



# CRUDS

#greeting = params[:greeting] || "Hi There"


post '/event' do
  puts params.inspect

  event = Event.new do |evt|
    evt.title = params[:title].strip
    evt.date = params[:daterange]
    evt.genre_id = params[:genre_id]
    evt.branch_id = params[:branch_id]
  end

  success = false

  ActiveRecord::Base.transaction do
    #event.save!

    counts = params[:counts].nil? ? {} : params[:counts].first

    counts.each do |category_id, attendants|
      count = Count.new do |ct|
        ct.event_id = event.id
        ct.category_id = category_id
        ct.attendants = attendants
      end
      #count.save!
    end

    success = true
  end

  "Hello World"
  #redirect "", errors: "wsdfasdf"
  redirect back 


end




put '/api/events' do

  # branch_id = params['branch_id']
  data = JSON.parse(request.body.read)

  puts data.class
  puts data.inspect

  event = Event.new do |evt|
    evt.date = data['date']
    evt.genre_id = data['genre_id']
    evt.branch_id = data['branch_id']
    evt.title = 'Godfoten'
    evt.description = data['desc'] # null?
  end

  success = false

  ActiveRecord::Base.transaction do
    event.save!

    count = Count.new do |ct|
      ct.event_id = event.id
      ct.category_id = data['category_id']
      ct.attendants = data['count']
    end

    count.save!
    success = true
  end


  {:success => success, :message => "alles gut"}.to_json
end


# needed when using the Sinatra::Reloader to avoid draining the connection pool
after do
  ActiveRecord::Base.clear_active_connections!
end
