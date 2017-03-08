# encoding: utf-8

require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'sinatra/flash'
require 'sinatra/cross_origin'
require "sinatra/reloader" if development?
require 'tilt/erb' if development?

require 'date'

require_relative 'models/models'
require_relative 'models/report'
require_relative 'settings'
require_relative 'log'

ActiveRecord::Base.establish_connection(Settings::DBWEB)

register Sinatra::Reloader if development?
set :bind, '0.0.0.0' if development?
set :port, 5100 if development?
enable :show_exceptions if development?

set :server, %w[thin webrick] if development?

enable :logging, :dump_errors, :raise_errors, :show_exceptions
disable :absolute_redirects

enable :cross_origin
register Sinatra::CrossOrigin

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => Settings::SECRET


# Sets up logging of uncaught errors
error_logger = ::File.new(::File.join(::File.dirname(::File.expand_path(__FILE__)),'logs','error.log'),"a+")
error_logger.sync = true

# Set up CORS support
configure do
  enable :cross_origin
end

set :allow_origin, :any
set :allow_methods, [:get, :post, :put, :options]
set :allow_credentials, true
set :max_age, "1728000"
set :expose_headers, ['Content-Type']


before do
  env["rack.errors"] = error_logger

   # content_type :json
   #headers 'Access-Control-Allow-Origin' => '*',
    #        'Access-Control-Allow-Methods' => ['OPTIONS', 'GET', 'POST', 'PUT']
end

options "*" do
  response.headers["Allow"] = "HEAD,GET,PUT,POST,OPTIONS"
  response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept"
  200
end


# needed when using the Sinatra::Reloader to avoid draining the connection pool
after do
  ActiveRecord::Base.clear_active_connections!
end

# for use by the 'settings' modal in layout.erb
set :branches, Branch.all

# ------------ helpers  -------------

def require_logged_in
  redirect('/login') unless is_authenticated?
end

def require_admin
  redirect('/login') unless is_admin?
end


def is_authenticated?
  session[:user_id]
end

def is_admin?
  session[:admin]
end

def protected!
  halt 401, "Beklager. Det kreves admin-rettigheter for å benytte denne siden." unless is_admin?
end

# ------------ routes  -------------

get '/' do
  if is_authenticated?
    erb :index
  else
    redirect('/login') #erb :login
  end
end

get '/login' do
  erb :login
end

get '/logout' do
  session.clear
  redirect('/')
end

get '/info' do
  require_logged_in
  erb :information
end

post '/sessions' do
  if params[:password].downcase == Settings::PW && params[:username].downcase == Settings::USERNAME
    session[:user_id] = params[:username].downcase
  end

  if params[:password] == Settings::PWADMIN && params[:username].downcase == Settings::ADMINNAME
    session[:user_id] = params[:username].downcase
    session[:admin] = params[:username].downcase
  end

  session.options[:expire_after] = 60*60*24*60 if session[:user_id].present? && params[:remember].present?

  session[:user_id] ? redirect('/settings') : redirect('/')
end

get '/settings' do
  require_logged_in
  erb :get_settings
end

get '/manage_events' do
  require_logged_in

  error = session.delete(:transaction_error)

  @edit = false
  @selected_branch = session[:default_branch] || '0'

  erb :manage_events, :locals => {branches: Branch.all, subcategories: Subcategory.all,
    subcategory_links: SubcategoryLink.all, age_groups: AgeGroup.all,
    event_types: EventType.ordered_view.all, error: error }
  end


  get '/edit_event/:event_id' do
    require_logged_in

    error = session.delete(:transaction_error)
    event_id = params['event_id']

    @edit = true
    event = Event.find(event_id)
    @selected_branch = event.branch_id

    erb :manage_events, :locals => {branches: Branch.all, subcategories: Subcategory.all,
      subcategory_links: SubcategoryLink.all, age_groups: AgeGroup.all,
      event_types: EventType.ordered_view.all, event: Event.find(event_id), error: error, is_admin: is_admin? }
    end


  get '/view_events' do
    require_logged_in

    # success = session.delete(:transaction_success) # why is this here?

    # TODO: sanitize input
    # parse parameters
    @per_page = params[:per_page] || session[:default_per_page] || '10'
    @per_page = '10' if @per_page.to_i < 1 ||  @per_page.to_i > 200

    @audience = params[:audience] || 'all'
    @sort_by = params[:sort_by] || 'reg'
    @sort_order = params[:sort_order] || 'desc'
    @month = params[:month] || ''
    @branch = params[:branch] || session[:default_branch] || ''
    @show_filters = params[:show_filters].present? && params[:show_filters] == 'true'

    # filter result set
    events = @sort_by == 'reg' ? Event.order_by_registration_date : Event.order_by_event_date
    events = events.by_age_group(@audience) unless @audience == 'all'
    events = events.by_branch(@branch) unless @branch.blank?

    if @month.present?
      start = Date.new(2017, @month.to_i ,1)
      stop = start.next_month.prev_day
      events = events.between_dates(start, stop)
    end

    # prepare page links
    page_number = params[:page_number].present? ? params[:page_number].to_i : 1
    limit = @per_page.to_i == 0 ? events.size : @per_page.to_i
    offset = (page_number - 1) * limit
    number_of_pages = events.size / limit
    number_of_pages += 1 if events.size % limit > 0 && events.size != limit
    page_number = 1 if page_number < 1 || page_number > number_of_pages

    page_start = page_number > 2 ? page_number - 2 : 1
    page_end = number_of_pages - page_number > 2 ? page_number + 2 : number_of_pages

    @page_array = (page_start..page_end).to_a
    @month_names = ["", "Jan", "Feb", "Mar", "Apr", "Mai", "Jun", "Jul", "Aug", "Okt", "Nov", "Des"]

    @link = "/view_events?per_page=#{@per_page}&audience=#{@audience}&sort_by=#{@sort_by}"
    @link += "&sort_order=#{@sort_order}&month=#{@month}&branch=#{@branch}&page_number="

    start = (page_number.to_i - 1) * limit

    # final cut
    events = @sort_order == 'desc' ? events.to_a.slice(start, limit) : events.to_a.reverse.slice(start, limit)

    erb :view_events, :locals => {events: events, branches: Branch.all,
       page_number: page_number, number_of_pages: number_of_pages}
  end


  get '/delete_event/:event_id' do
    protected!
    event = Event.find(params['event_id'])

    log_message = "DELETED EVENT: " + event.inspect
    logger.info log_message
    Log.log.info log_message

    event.destroy!

    redirect('/view_events')
  end

  get '/manage_categories' do
    protected!
    erb :manage_categories, :locals => {def_url: "/api/subcategory_definition",
      pri_url: "/api/subcategory_priority_list",success: nil, id: nil, collection: Subcategory.all}
  end

  get '/manage_event_types' do
    protected!
    erb :manage_categories, :locals => {def_url: "/api/event_type_definition",
       pri_url: "/api/event_type_priority_list", success: nil, id: nil, collection: EventType.all}
  end

  get '/manage_age_groups' do
    protected!
    erb :manage_categories, :locals => {def_url: "/api/age_group_definition",
       pri_url: "/api/age_group_priority_list", success: nil, id: nil, collection: AgeGroup.all}
  end

  get '/schema' do
    protected!

    erb :schema, :locals => {branches: Branch.all, subcategories: Subcategory.all,
      categories: Category.all, subcategory_links: SubcategoryLink.all, age_groups: AgeGroup.all, event_types: EventType.all,
      event_maintypes: EventMaintype.all, event_subtypes: EventSubtype.all}
    end



  get '/view_statistics' do
    require_logged_in

    error = session.delete(:transaction_error)
    @selected_branch = session[:default_branch] || '0'

    erb :statistics, :locals => {branches: Branch.all, subcategories: Subcategory.all,
      categories: Category.all, subcategory_links: SubcategoryLink.all, age_groups: AgeGroup.all, event_types: EventType.all,
      event_maintypes: EventMaintype.all, event_subtypes: EventSubtype.all}
    end


    get '/enable_javascript' do
      erb :enable_javascript, :layout => false
    end


    # CRUDS

    post '/api/subcategory_definition' do
      protected!

      id = params[:id].to_i
      definition = params[:definition]

      subcategory = Subcategory.find(id)
      subcategory.definition = definition

      success = subcategory.save

      erb :manage_categories, :locals => {def_url: "/api/subcategory_definition",
         pri_url: "/api/subcategory_priority_list", success: success, id: id, collection: Subcategory.all}
    end


    post '/api/event_type_definition' do
      protected!

      id = params[:id].to_i
      definition = params[:definition]

      item = EventType.find(id)
      item.definition = definition

      success = item.save

      erb :manage_categories, :locals => {def_url: "/api/event_type_definition",
         pri_url: "/api/event_type_priority_list", success: success, id: id, collection: EventType.all}
    end

    post '/api/age_group_definition' do
      protected!

      id = params[:id].to_i
      definition = params[:definition]

      item = AgeGroup.find(id)
      item.definition = definition

      success = item.save

      erb :manage_categories, :locals => {def_url: "/api/age_group_definition",
         pri_url: "/api/age_group_priority_list", success: success, id: id, collection: AgeGroup.all}
    end

    # ---------------------------------------------------------------------------

    post '/api/subcategory_priority_list' do
      protected!

      priority_list = JSON.parse( request.body.read)["priority_list"]
      update_priority_list("Subcategory", priority_list)
    end


    post '/api/event_type_priority_list' do
      protected!

      priority_list = JSON.parse( request.body.read)["priority_list"]
      update_priority_list("EventType", priority_list)
    end

    post '/api/age_group_priority_list' do
      protected!

      priority_list = JSON.parse( request.body.read)["priority_list"]
      update_priority_list("AgeGroup", priority_list)
    end


    def update_priority_list(model_name, priority_list)
      model = model_name.constantize
      success = false

      ActiveRecord::Base.transaction do
        priority_list.each do |id, priority|
          model.find(id).update!(view_priority: priority)
        end
        success = true
      end

      if success
        status 200
        {message: "OK. Lagret"}.to_json
      else
        status 400
        {message: "Beklager, det oppsto en feil"}.to_json
      end
    end

    # --------------------------------------------------------------------------

    get '/api/basics' do
      event_types = []
      EventType.all.each do |et|
        event_types << {
          value: et.id,
          text: et.name,
          maintype_id: et.event_maintype_id,
          subtype_id: et.event_subtype_id,
          subcategories: et.subcategory_ids,
          categories: et.category_ids,
          age_groups: et.age_group_ids
        }
      end

      categories = []
      Category.all.each do |cat|
        categories << {
          value: cat.id,
          text: cat.name
        }
      end

      subcategories = []
      Subcategory.all.each do |cat|
        subcategories << {
          value: cat.id,
          text: cat.name
        }
      end

      subtypes = []
      EventSubtype.all.each do |type|
        subtypes << {
          value: type.id,
          text: type.name,
          subcategories: type.event_type.subcategory_ids,
          categories: type.event_type.category_ids,
        }
      end

      maintypes = []
      EventMaintype.all.each do |type|
        maintypes << {
          value: type.id,
          text: type.label,
          subcategories: type.subcategory_ids,
          categories: type.category_ids,
          subtypes: type.event_subtype_ids
        }
      end

      branches = []
      Branch.all.each do |branch|
        branches << {
          value: branch.id,
          text: branch.name
        }
      end

      age_groups = []
      AgeGroup.all.each do |agegroup|
        age_groups << {
          value: agegroup.id,
          text: agegroup.name # lage label?
        }
      end

      {types: event_types, maintypes: maintypes, subtypes: subtypes, categories: categories,
        subcategories: subcategories, branches: branches, agegroups: age_groups}.to_json

      #  {maintypes: maintypes}.to_json
    end


    post '/api/event' do
      require_logged_in

      is_edit = params[:id].present?
      event_id = params[:id].to_i if is_edit

      event = is_edit ? Event.find(event_id) : Event.new
      event.attributes = event.attributes.merge(params) {|key, oldVal, newVal| key == 'id' ? oldVal : newVal}
      event.marked_for_deletion = params[:marked_for_deletion].present?

      category = event.event_type.get_category_id_by(event.subcategory_id)
      event.category_id = category.id

      if event.save
        type = is_edit ? "MODIFY EVENT: " : "ADD EVENT: "
        logger.info type + event.inspect
        Log.log.info type + event.inspect

        session[:transaction_success] = true
        erb :receipt, :locals => {event: event}
      else
        session[:transaction_error] = true
        redirect '/edit_event/' + event.id.to_s
      end
    end

    put '/api/settings' do
      data = JSON.parse(request.body.read)
      session[:default_branch] = data['defaultBranch']
      session[:default_per_page] = data['defaultPerPage']
    end

    put '/api/statistics' do
      # require_logged_in
      # TODO sanitize input

      data = JSON.parse(request.body.read)
      branch_id = data['branch_id']
      category_id = data['category_id']
      subcategory_id = data['subcategory_id']
      age_group_id = data['age_group_id']
      @from_date = Date.parse(data['from_date'])
      @to_date = Date.parse(data['to_date'])

      maintype_id = data['maintype_id']
      subtype_id = data['subtype_id']

      report_builder = ReportBuilder.new
      report_builder.set_dates(@from_date, @to_date)
      report_builder.set_branch(branch_id)
      report_builder.set_age_group(age_group_id)
      report_builder.set_type(maintype_id, subtype_id)
      report_builder.set_category(category_id, subcategory_id)

      report = report_builder.report
      report.get_results
    end
