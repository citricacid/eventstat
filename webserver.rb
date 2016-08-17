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
enable :show_exceptions if development?

set :server, %w[thin webrick]
set :sessions, key: Settings::SESSION_KEY, secret: Settings::SECRET

#I18n.available_locales = [:no]
#I18n.locale = :no

#I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
#I18n.load_path = Dir['config/locales/*.yml']
#I18n.backend.load_translations

#puts I18n.t(:hello)
#puts I18n.t(:hello_world)

etc = EventType.find(6)
#puts etc.age_group_array
puts etc.subcategory_array
#etc.foo
#etc.foo

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

  erb :manage_events, :locals => {branches: Branch.all, subcategories: Subcategory.all,
    age_groups: AgeGroup.all, event_types: EventType.all, edit: false, error: error }
  end


  get '/view_events' do
    require_logged_in

    success = session[:transaction_success] == true
    session[:transaction_success] = nil

    page_number = params[:page_number].present? ? params[:page_number].to_i : 1
    limit = params[:viev_all].present? ? Event.all.size : 10
    offset = (page_number - 1) * limit
    number_of_pages = Event.all.size / limit
    number_of_pages += 1 if Event.all.size % limit > 0

    erb :view_events, :locals => {events: Event.reverse.limit(limit).offset(offset), branches: Branch.all,
       success: success, page_number: page_number, number_of_pages: number_of_pages}
  end


  get '/edit_event/:event_id' do
    require_logged_in

    error = session[:transaction_error] == true
    session[:transaction_error] = nil

    event_id = params['event_id']

    erb :manage_events, :locals => {branches: Branch.all, subcategories: Subcategory.all,
      age_groups: AgeGroup.all, event_types: EventType.all, event: Event.find(event_id), edit: true, error: error }

  end


  get '/view_statistics' do
    require_logged_in

    error = session[:transaction_error] == true
    session[:transaction_error] = nil

    erb :statistics, :locals => {branches: Branch.all, subcategories: Subcategory.all,
      categories: Category.all, age_groups: AgeGroup.all, event_types: EventType.all,
      event_maintypes: EventMaintype.all, event_subtypes: EventSubtype.all}
    end


    get '/enable_javascript' do
      erb :enable_javascript
    end


    # CRUDS

    post '/api/event' do
      require_logged_in

      data = JSON.parse(request.body.read)
      event_data = data['event_data']
      count_data = data['count_data']

      is_edit = event_data['id'].present?
      event_id = event_data['id'].to_i if is_edit

      event = is_edit ? Event.find(event_id) : Event.new
      event.attributes = event.attributes.merge(event_data) {|key, oldVal, newVal| key == 'id' ? oldVal : newVal}

      success = false

      ActiveRecord::Base.transaction do
        event.save!

        if is_edit
          old_counts = Count.where('event_id = ?', event_id)
          old_counts.each do |ct|
            ct.destroy!
          end
        end

        count_data.each do |age_group_id, attendants|
          count = Count.new do |ct|
            ct.event_id = event.id
            ct.age_group_id = age_group_id
            ct.attendants = attendants
          end
          count.save!
        end

        success = true
      end

      if success
        session[:transaction_success] = true
        {redirect: '/view_events'}.to_json

      else
        session[:transaction_error] = true
        {redirect: '/edit_event/' + event.id.to_s}.to_json
      end
    end


    put '/api/statistics' do
      data = JSON.parse(request.body.read)
      branch_id = data["branch_id"]
      category_id = data["category_id"]
      subcategory_id = data["subcategory_id"]
      @from_date = Date.parse(data["from_date"])
      @to_date = Date.parse(data["to_date"])

      maintype_id = data["maintype_id"]
      subtype_id = data["subtype_id"]


      puts data.inspect
      # if event_type_id == 'sum_all' then...
      # if event_type_id == 'iterate_all'

      # if event_maintype == 'sum_all' then ...
      # if event_maintype == 'iterate_all' then ...

      # if event_subtype == ' '



      report_builder = ReportBuilder.new
      report_builder.set_dates(@from_date, @to_date)
      report_builder.set_branch(branch_id)
      report_builder.set_category(category_id, subcategory_id)
      report_builder.set_type(maintype_id, subtype_id)

      report = report_builder.report
      res = report.get_results
      res


    end


    # needed when using the Sinatra::Reloader to avoid draining the connection pool
    after do
      ActiveRecord::Base.clear_active_connections!
    end
