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
  redirect('/login') unless is_authenticated?
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
  puts params[:password]
  if params[:password] == Settings::PW
    session[:user_id] = params[:username]
  end

  if params["pw"] == Settings::PWADMIN
    session[:user_id] = params["user_id"]
    session[:admin] = params["user_id"]
  end

  redirect('/')
end

get '/manage_events' do
  require_logged_in

  error = session[:transaction_error] == true
  session[:transaction_error] = nil

  erb :manage_events, :locals => {branches: Branch.all, genres: Genre.all,
     categories: Category.all, edit: false, error: error }
end


get '/view_events' do
  require_logged_in

  success = session[:transaction_success] == true
  session[:transaction_success] = nil

  erb :view_events, :locals => {events: Event.all, branches: Branch.all, success: success}
end


get '/edit_event/:event_id' do
  require_logged_in

  event_id = params['event_id']

  erb :manage_events, :locals => {branches: Branch.all, genres: Genre.all,
    categories: Category.all, event: Event.find(event_id), edit: true, error: false }
end



# CRUDS


post '/event' do
  require_logged_in

  is_edit = params[:event_id].present?
  event_id = params[:event_id].to_i if is_edit

  event = is_edit ? Event.find(event_id) : Event.new

  event.title = params[:title].strip
  event.date = params[:daterange]
  event.genre_id = params[:genre_id]
  event.branch_id = params[:branch_id]

  success = false

  ActiveRecord::Base.transaction do
    event.save!

    if is_edit
      old_counts = Count.where('event_id = ?', event_id)
      old_counts.each do |ct|
        ct.destroy!
      end
    end

    counts = params[:counts].nil? ? {} : params[:counts].first
    counts.each do |category_id, attendants|
      count = Count.new do |ct|
        ct.event_id = event.id
        ct.category_id = category_id
        ct.attendants = attendants
      end
      count.save!
    end

    success = true
  end

  if success
    session[:transaction_success] = true
    redirect "/view_events"
  else
    session[:transaction_error] = true
    redirect back
  end
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
