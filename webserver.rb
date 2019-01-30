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

set :static_cache_control, [:public, {:max_age => 60*60*24}]

before do
  env["rack.errors"] = error_logger

  begin
    @default_branch = Branch.find(session[:default_branch]) if defined?(session)
  rescue
    @default_branch = nil
  end
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

  #session[:user_id] ? redirect('/') : redirect('/')
  redirect('/')
end

get '/settings' do
  require_logged_in
  erb :get_settings
end



get '/manage_schema' do
  protected!

  erb :manage_schema, :locals => {subcategories: [Subcategory.new({name: '-- Ny --'}), *Subcategory.all],
    types: Subcategory.subclasses.map {|s| s.to_s} }
end


get '/manage_event' do
  require_logged_in

  selected_branch = session[:default_branch]
  item = Event.new
  item.branch_id = selected_branch if selected_branch.present?

  erb :manage_event, :locals => get_event_locals.merge!({is_edit: false, is_event: true, item: item})
end

get '/edit_event/:event_id' do
  require_logged_in
  item = Event.find(params[:event_id])

  erb :manage_event, :locals => get_event_locals.merge!({is_edit: true, is_event: true, item: item})
end

get '/clone_event/:event_id' do
  require_logged_in
  item = Event.find(params[:event_id]).dup

  item.attendants = nil
  item.date = nil
  item.is_locked = 0
  item.marked_for_deletion = 0
  item.added_after_lock = 0

  erb :manage_event, :locals => get_event_locals.merge!({is_edit: true, is_event: true, item: item})
end

get '/edit_template/:template_id' do
  protected!
  item = Template.find(params[:template_id])

  erb :manage_event, :locals => get_event_locals.merge!({is_edit: true, is_event: false, item: Template.find(params[:template_id])})
end

get '/manage_template' do
  protected!

  error = session.delete(:transaction_error)
  selected_branch = session[:default_branch] || '0'

  erb :manage_event, :locals => get_event_locals.merge!({is_edit: false, is_event: false, item: nil})
end

#TODO find better name
get '/add_event/:template_id' do
  require_logged_in

  error = session.delete(:transaction_error)
  selected_branch = session[:default_branch] || '0'

  erb :manage_event, :locals => get_event_locals.merge!({is_edit: false, is_event: true, item: Template.find(params[:template_id])})
end


def get_event_locals
  selected_branch = session[:default_branch] || '0'
  error = session.delete(:transaction_error)

  {selector_type: :form, branches: Branch.all,
    subcategories: Subcategory.all, internal_subcategories: InternalSubcategory.all,
    aggregated_subcategories: AggregatedSubcategory.all,
    age_groups: AgeGroup.all, selected_branch: selected_branch, event_types: EventType.ordered_view.all,
    is_admin: is_admin?, district_categories: DistrictCategory.all, error: error
  }
end


  # ////////////////////////////////////////////////////////////////////////////

  get '/view_events' do
    require_logged_in

    # TODO: sanitize input
    parse_parameters
    erb :view_events, :locals => {branches: Branch.all, categories: Category.all, subcategories: Subcategory.all }

  end

  get '/ajax/search' do
    require_logged_in

    # TODO: sanitize input
    parse_parameters
    events = filter_result_set
    prepare_page_links(events)

    start = (@page_number.to_i - 1) * @limit

    # final cut
    events = @sort_order == 'desc' ? events.to_a.slice(start, @limit) : events.to_a.reverse.slice(start, @limit)

    {tablerows: generate_tablerows(events), page_links: generate_page_links}.to_json
  end

  def parse_parameters
    @per_page = params[:per_page] || session[:default_per_page] || '10'
    @per_page = '10' if @per_page.to_i < 1 ||  @per_page.to_i > 200

    @audience = params[:audience] || 'all'
    @sort_by = params[:sort_by] || 'reg'
    @sort_order = params[:sort_order] || 'desc'
    @month = params[:month] || ''
    @year = params[:year] || '2017'
    @branch_id = params[:branch] || session[:default_branch] || ''
    @show_marked = params[:show_marked] || 'none'
    @show_filters = params[:show_filters].present? && params[:show_filters] == 'true'
    @search = params[:search] || ''
    @page_number = params[:page_number].present? ? params[:page_number].to_i : 1

    @category_id = params[:category]
    @subcategory_id = params[:subcategory]

    @month_names = ["", "Jan", "Feb", "Mar", "Apr", "Mai", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Des"]
  end

  def filter_result_set
    events = @sort_by == 'reg' ? Event.order_by_registration_date : Event.order_by_event_date
    events = events.by_age_category(@audience) unless @audience == 'all'
    events = events.by_branch(@branch_id) unless @branch_id.blank? || @branch_id == '0'
    events = events.by_category(@category_id) unless @category_id.blank? || @category_id == 'all'
    events = events.by_subcategory(@subcategory_id) unless @subcategory_id.blank? || @subcategory_id == 'all'

    if @show_marked == 'none'
      events = events.where(marked_for_deletion: 0)
    elsif @show_marked == 'only'
      events = events.where(marked_for_deletion: 1)
    end

    if @month.present?
      start = Date.new(@year.to_i, @month.to_i , 1)
      stop = start.next_month.prev_day
      events = events.between_dates(start, stop)
    end

    if @search.present?
      # events = events.where('MATCH (name) AGAINST(? IN BOOLEAN MODE)', @search + '*')
      #events = events.where('name LIKE ?', "%#{@search}%")
      events = events.search(@search)
    end

    events
  end

  def prepare_page_links(events)
    @limit = @per_page.to_i < 1 ? 10 : @per_page.to_i
    #offset = (@page_number - 1) * limit
    @number_of_pages = events.size / @limit
    @number_of_pages += 1 if events.size % @limit > 0 && events.size != @limit
    @page_number = 1 if @page_number < 1 || @page_number > @number_of_pages

    page_start = @page_number > 2 ? @page_number - 2 : 1
    page_end = @number_of_pages - @page_number > 2 ? @page_number + 2 : @number_of_pages
    @page_array = (page_start..page_end).to_a

    @link = %Q(
      /view_events?per_page=#{@per_page}&audience=#{@audience}&sort_by=#{@sort_by}
      &show_filters=#{@show_filters}&show_marked=#{@show_marked}&search=#{@search}
      &sort_order=#{@sort_order}&month=#{@month}&branch=#{@branch_id}&page_number=
    ).delete(' ')
  end

  def generate_tablerows(events)
    tablerows = ''

    events.each do |event|
      if event.marked_for_deletion == 1
        style = 'text-decoration: line-through; color:red;'
        icon = 'glyphicon-edit btn-danger'
      elsif event.is_locked == 1
        style = ''
        icon = 'glyphicon-lock'
      else
        style = ''
        icon = 'glyphicon-edit'
      end

      tablerows <<  %Q(
      <tr style='#{style}'>
      <td>#{event.name}</td><td>#{event.date.strftime('%d/%m/%-y')}</td>
      <td>#{event.attendants}</td>
      <td><a href='/edit_event/#{event.id}'><span class='glyphicon #{icon}'></span></a></td>
      </tr>
      )
    end

    tablerows
  end

  def generate_page_links
    page_links = %Q(
    <div class='col col-xs-4'>
    Side <span id="page_number">#{@page_number}</span> av #{@number_of_pages}
    </div>
    <div class='col col-xs-8'>
    <nav aria-label='Page navigation'>
    <ul class='pagination pull-left'>
    <li class='page-item'>
    <a class='page-link' data-page='1' href='javascript:void(0)' aria-label='Første'>
    <span aria-hidden='true'>&laquo;</span>
    <span class='sr-only'>Første</span>
    </a>
    </li>
    )

    if @page_number > 1
      page_links += %Q(
      <li class='page-item'>
      <a class='page-link' data-page='#{(@page_number - 1)}' href='javascript:void(0)' aria-label='Forrige'>
      <span aria-hidden='true'><</span>
      <span class='sr-only'>Forrige</span>
      </a></li>
      )
    end


    @page_array.each do |i|
      is_active = i == @page_number ? 'active' : ''
      page_links += %Q(<li class='page-item #{is_active}'><a class='page-link' data-page='#{i}' href='javascript:void(0)'>#{i}</a></li>)
    end

    if @page_number < @number_of_pages
      page_links += %Q(
      <li class='page-item'>
      <a class='page-link' data-page='#{(@page_number + 1)}' href='javascript:void(0)' aria-label='Neste'>
      <span aria-hidden='true'>></span>
      <span class='sr-only'>Neste</span>
      </a></li>
      )
    end

    page_links += %Q(
    <li class="page-item">
    <a class='page-link' data-page='#{@number_of_pages}' href='javascript:void(0)' aria-label='Siste'>
    <span aria-hidden="true">&raquo;</span>
    <span class="sr-only">Siste</span>
    </a>
    </li>
    </ul>
    </nav>
    </div>
    )
  end

  # ////////////////////////////////////////////////////////////////////////////



  get '/delete_event/:event_id' do
    protected!
    event = Event.find(params['event_id'])

    log_message = "DELETED EVENT: " + event.inspect
    logger.info log_message
    Log.log.info log_message

    event.destroy!

    redirect('/view_events')
  end


  get '/mark_event/:event_id' do
    require_logged_in
    event = Event.find(params['event_id'])

    log_message = "MARKED EVENT FOR DELETION: " + event.inspect
    logger.info log_message
    Log.log.info log_message

    event.marked_for_deletion = true
    event.save! unless event.is_locked == 1 # makes no sense to mark locked event - just a minor safeguard

    redirect('/view_events?show_marked=all')
  end

  get '/unmark_event/:event_id' do
    require_logged_in
    event = Event.find(params['event_id'])

    log_message = "UNMARKED EVENT FOR DELETION: " + event.inspect
    logger.info log_message
    Log.log.info log_message

    event.marked_for_deletion = false
    event.save!

    redirect('/view_events')
  end


  # ////////////////////////////////////////////////////////////////////////////

  get '/manage_locks' do
    require_logged_in

    @selected_branch = params[:branch_id] || session[:default_branch]
    @events = []
    begin
      branch = Branch.where(id: @selected_branch).first!

      current_lock_date = branch.locked_until.next_day
      new_lock_date = (params[:to_date] && Date.parse(params[:to_date])) || Date.today.prev_day
      new_lock_date = current_lock_date if new_lock_date < current_lock_date

      @from_date = current_lock_date.strftime('%d-%m-%Y')
      @to_date = new_lock_date.strftime('%d-%m-%Y')

      @events = Event.order_by_event_date
        .by_branch(branch.id)
        .between_dates(current_lock_date, new_lock_date)
      @unmarked_count = @events.where(marked_for_deletion: 0).size
      @marked_count = @events.where(marked_for_deletion: 1).size
    rescue
      puts "it gone wrong" # todo
    end

    erb :manage_locks, :locals => {branches: Branch.all}
  end

  get '/ajax/get_lock_date' do
    #events.by_branch(@branch)
    branch = Branch.where(id: params[:branch_id]).first
    {current_lock_date: branch.locked_until.strftime('%d-%m-%Y')}.to_json
  end

  get '/ajax/get_events' do
    require_logged_in

    branch = Branch.where(id: params[:branch_id]).first
    current_lock_date = branch.locked_until
    new_lock_date = params[:new_date]

    # todo if new_date > cur_date
    events = Event.order_by_event_date.by_branch(branch.id).between_dates(current_lock_date, new_lock_date)

    {events: events}.to_json
  end

  post '/api/lock' do
    require_logged_in

    success = Branch.activate_lock(params[:branch_id], params[:to_date])
    @message = success ? "Ok. Lagret" : "Beklager. Feil oppsto"
    redirect back
  end

  # ////////////////////////////////////////////////////////////////////////////

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
      categories: Category.all, subcategory_links: SubcategoryLink.all,
      age_groups: AgeGroup.all, event_types: EventType.all,
      event_maintypes: EventMaintype.all, event_subtypes: EventSubtype.all}
  end

  # ////////////////////////////////////////////////////////////////////////////
  Group = Struct.new(:id, :name)

  get '/view_statistics' do
    require_logged_in

    error = session.delete(:transaction_error)
    selected_branch = session[:default_branch] || '0'

    categories = AgeGroup.age_categories.map {|k,v| Group.new(v, AgeGroup.get_label(k))}

    erb :statistics, :locals => {selector_type: :stats, branches: Branch.all, subcategories: Subcategory.all,
      internal_subcategories: InternalSubcategory.all, district_categories: DistrictCategory.all, categories: Category.all,
      age_groups: AgeGroup.all, age_categories: categories, event_types: EventType.all,
      event_maintypes: EventMaintype.all, event_subtypes: EventSubtype.all,
      selected_branch: selected_branch, queries: Query.all, compound_queries: CompoundQuery.all}
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

    # TODO add headers, strategies
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


    # -----------------------------------------------------------------------

    get '/view_templates' do
      protected!
      selected_branch = session[:default_branch] || '0'

      erb :view_templates, :locals => {branches: Branch.all, selected_branch: selected_branch, templates: Template.all}
    end

    post '/api/template' do
      protected!

      is_edit = params[:id].present?
      event_id = params[:id].to_i if is_edit

      event = is_edit ? Template.find(event_id) : Template.new
      updates = params.select {|key| event.attributes.key?(key)}
      event.attributes = event.attributes.merge(updates) {|key, oldVal, newVal| key == 'id' ? oldVal : newVal}

      # infer categories
      event.district_category_id = nil if !event.branch.has_district_category

      category = event.event_type.get_category_id_by(event.subcategory_id)
      event.category_id = category.id

      if event.save
        type = is_edit ? "MODIFY TEMPLATE: " : "ADD TEMPLATE: "
        logger.info type + event.inspect
        Log.log.info type + event.inspect

        session[:transaction_success] = true
        erb :receipt, :locals => {item: event, is_event: false}
      else
        session[:transaction_error] = true
        redirect '/edit_template/' + event.id.to_s
      end
    end



    # -----------------------------------------------------------------------

    post '/api/event' do
      require_logged_in

      is_edit = params[:id].present?
      event_id = params[:id].to_i if is_edit

      # populate attributes
      event = is_edit ? Event.find(event_id) : Event.new
      updates = params.select {|key| event.attributes.keys.include?(key) }
      event.attributes = event.attributes.merge(updates) {|key, oldVal, newVal| key == 'id' ? oldVal : newVal}

      # infer categories
      event.district_category_id = nil if !event.branch.has_district_category

      category = event.event_type.get_category_id_by(event.subcategory_id)
      event.category_id = category.id

      if event.subcategory.is_a?(DistrictSubcategory)
        event.aggregated_subcategory_id = event.branch.aggregated_subcategory_id
      else
        event.aggregated_subcategory_id = nil
      end

      # lock handling
      event.added_after_lock = 1 if !is_edit && event.date < event.branch.locked_until
      protected! if event.is_locked == 1

      if event.save
        type = is_edit ? "MODIFY EVENT: " : "ADD EVENT: "
        logger.info type + event.inspect
        Log.log.info type + event.inspect

        session[:transaction_success] = true
        erb :receipt, :locals => {item: event, is_event: true, templates: event.branch.templates}
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


    # ////////////////////////////////////////////////////////////////

    # QUERY

    post '/api/query' do
      accepted_values = %w(name maintype_id subtype_id category_id subcategory_id age_category_id age_group_id)
      data = params.select {|key, value| accepted_values.include?(key) }

      query_name = data.delete("name")

      query = Query.find_or_initialize_by(name: query_name)
      query.save!

      query.query_parameters.each  {|element| element.delete}

      data.each do |name, value|
        QueryParameter.new(query_id: query.id, element_name: name, element_value: value).save
      end
      # name.blank? raise error

    end


    get '/api/queries' do
      Query.all.to_json
    end

    get '/api/queries/:query_id' do
      Query.includes(:query_parameters).find(params[:query_id]).to_json
    end

    get '/q' do
      protected!
      categories = AgeGroup.age_categories.map {|k,v| Group.new(v, AgeGroup.get_label(k))}

      erb :generate_query, :locals => {selector_type: :stats, branches: Branch.all, subcategories: Subcategory.all,
        internal_subcategories: InternalSubcategory.all, district_categories: DistrictCategory.all, categories: Category.all,
        age_groups: AgeGroup.all, age_categories: categories, event_types: EventType.all,
        event_maintypes: EventMaintype.all, event_subtypes: EventSubtype.all,
        selected_branch: nil, queries: Query.all}
    end

    put '/api/statistics' do
      require_logged_in
      # TODO sanitize input

      data = JSON.parse(request.body.read, opts = {symbolize_names: true})
      Report.new(data).get_results
    end
