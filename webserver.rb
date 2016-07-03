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
set :port, 5100 if development?

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
  if params[:password] == Settings::PW
    session[:user_id] = params[:username]
  end

  if params["pw"] == Settings::PWADMIN
    session[:user_id] = params["user_id"]
    session[:admin] = params["user_id"]
  end

  session.options[:expire_after] = 60*60*24*60 if session[:user_id].present? && params[:remember].present?

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


    get '/view_statistics' do
      require_logged_in

      error = session[:transaction_error] == true
      session[:transaction_error] = nil

      erb :statistics, :locals => {branches: Branch.all, genres: Genre.all, categories: Category.all}
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


    put '/api/statistics' do
      data = JSON.parse(request.body.read)
      branch_id = data["branch_id"]
      genre_id = data["genre_id"]
      @from_date = Date.parse(data["from_date"])
      @to_date = Date.parse(data["to_date"])

      iterate_over_branches = branch_id == '-1' ? true : false
      branch_id = nil if branch_id == '0' || branch_id == '-1'

      iterate_over_genres = genre_id == '-1' ? true : false
      genre_id = nil if genre_id == '0' || genre_id == '-1'

      results = []


      if iterate_over_branches
        Branch.all.each do |branch|
          if iterate_over_genres
            results << iterate_genres(branch.id)
          else
            events = get_events(branch.id, genre_id)
            results << calculate_result(branch.name, events, events.size())
          end
        end
      elsif iterate_over_genres
        results << iterate_genres(branch_id)
      else
          branch_name = branch_id.nil? ? "Samlet" : Branch.find(branch_id).name
          events = get_events(branch_id, genre_id)
          results << calculate_result(branch_name, events, events.size())
      end

      {results: results}.to_json
    end


    def get_events (branch_id, genre_id)
      Event.between_dates(@from_date, @to_date).by_branch(branch_id).by_genre(genre_id)
    end

    def iterate_genres(branch_id)
      results = []

      Genres.all.each do |genre|
        events = get_events(branch_id, genre.id)
        results << calculate_result(branch.name, events, events.size())
      end
      results
    end

    def calculate_result(branch_name, events, size)
      all_ages_count = 0
      young_ages_count = 0

      events.each do |event|
        all_ages_count += event.counts.sum_all_ages
        young_ages_count += event.counts.sum_young_ages
      end

      {branch_name: branch_name, all: all_ages_count, young: young_ages_count, no_of_events: events.size()}
    end
