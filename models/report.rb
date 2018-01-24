# encoding: utf-8
#require 'csv' # need this anymore?


# Filter:
# collection - activerecord collection
# sum_all - boolean flag, if set to false then the collection will be iterated over
# sum_multipe_as_one: fucked if I know
Filter = Struct.new(:collection, :sum_all, :sum_multiple_as_one)

# LineItem:
# Used during filter traversal to generate labels for the table columns
LineItem = Struct.new(:id, :label)

# HeaderItem:
# Simple struct for generating the table headers
#
# :label - for the table headers
# :id - marker for matching table data with the correct column
# :is_countable - boolean flag indicating whether the column values should be accumulated
# :is_visible - boolean flag
HeaderItem = Struct.new(:label, :id, :is_countable, :is_visible)


class HeaderManager
  #attr_accessor :headers

  def initialize
    @items = []

    # fixed headers
    @items << HeaderItem.new("Periode", "period", false, true)
    @items << HeaderItem.new("Sted", "branch_name", false, true)

    # dynamic headers
    @items << HeaderItem.new("Type", "maintype", false, false)
    @items << HeaderItem.new("Undertype", "subtype", false, false)
    @items << HeaderItem.new("Kategori", "category", false, false)
    @items << HeaderItem.new("Underkategori", "subcategory", false)
    @items << HeaderItem.new("Alder", "agecategory", false, false)
    @items << HeaderItem.new("Alder", "agegroup", false, false)

    # fixed, countable headers
    @items << HeaderItem.new("Ant. arr", "no_of_events", true, true)
    @items << HeaderItem.new("Ant. deltagere", "no_of_attendants", true, true)
  end

  def get_headers
    @items
  end

  def get_visible_headers
    @items.select {|item| item.is_visible}
  end

  def add_visible_headers(item_id)
    ids = [*item_id]
    @items.each {|item| item.is_visible = true if ids.include?(item.id)}
  end

end


module Mod

  def Mod.create_filter(id, klazz)
    id = parse_value(id)
    sum_all = id == 'sum_all'
    collection = id == 'iterate_all' ? klazz.all : klazz.where(id: id)
    Filter.new(collection, sum_all)
  end


  def Mod.parse_value(input)
    %w(iterate_all sum_all none).include?(input) ? input : input.split(',')
  end

end


#
# Report
# TODO update this documentation
# Setters for defining the filters for the final report.
#
# Parameters: The id parameters can have the following values:
# - 'iterate_all' - report will iterate over all existing items (one lite item for each)
# - 'sum_all' - all existing items will be lumped as one
# - 'none' - for mutually exclusive categories...
# - single id or list of id values



class Report
  include Mod

  def initialize(args)
    @header_man = HeaderManager.new

    # build static portion of query
    static_keys = %i(period_label from_date to_date branch_id)
    static_arguments = args.select {|key| static_keys.include?(key)}
    q = Q.new(static_arguments)

    # build dynamic portion of query
    @queries = []
    if args[:compound_query_id].present?
      compound_query = CompoundQuery.find(args[:compound_query_id])

      query_list = compound_query.queries.map do |query|
        query_map = {}
        query.query_parameters.each {|parameter| query_map[parameter.element_name.to_sym] = Mod.parse_value(parameter.element_value)}
        query_map
      end

      query_list.each do |query|
        @queries << Subquery.new(q, query)
      end
    else
      dynamic_keys = %i(maintype_id subtype_id category_id district_category_id subcategory_id district_category_id
       age_group_id age_category_id use_district_categories expand_district_subcategories)
      dynamic_arguments = args.select {|key| dynamic_keys.include?(key)}
      @queries << Subquery.new(q, dynamic_arguments)
    end

    # get visible header keys
    @queries.each do |query|
      @header_man.add_visible_headers(query.get_visible_headers)
    end

  end

  def get_results
    headers = @header_man.get_visible_headers
    compound_results = []
    @queries.each do |query|
      compound_results << query.get_results(headers)
    end

    compound_results.flatten!
    compound_results.sort! {|x,y| x[:branch_name] <=> y[:branch_name] }

    {headers: headers, results: compound_results.flatten}.to_json
  end

end



class Q
  include Mod

  attr_accessor :period_label, :from_date, :to_date, :branches, :include_district_subcategories

  # TODO rescue invalid dates
  # TODO accept branch codes as well as id; rescue invalid branch id/code
  def initialize(args)
    @from_date = Date.parse(args[:from_date])
    @to_date = Date.parse(args[:to_date])
    @period_label = args[:period_label]

    branch_id = args[:branch_id]
    @branches = Mod.create_filter(branch_id, Branch)

    # TODO this only works as long as there is only one set of district subcategories
    # a better solution would figure out which district subcategories should be included
    #
    # also, allow for libraries who do not use district cats/subcats
    @include_district_subcategories = %w(sum_all iterate_all).include?(branch_id) || Branch.where(id: branch_id).where(has_district_category: 1).count > 0
  end

end

# results should have: headers, data, template
# use one standard header, and set template data

class Subquery
  include Mod

  # attr_accessor :category_type, :categories, :maintypes, :subtypes, :age_groups, :results, :q, :headers

  def initialize(q, args)
    @q = q

    @maintypes = Mod.create_filter(args[:maintype_id], EventMaintype)
    @subtypes = Mod.create_filter(args[:subtype_id], EventSubtype)

    # handle categories
    if args[:category_id].present? && args[:category_id] != 'none'
      set_category(args[:category_id], args[:use_district_categories].present?)
    elsif args[:district_category_id].present? && args[:district_category_id] != 'none'
      set_category(args[:district_category_id], args[:use_district_categories].present?)
    elsif args[:subcategory_id].present? && args[:subcategory_id] != 'none'
      set_subcategory(args[:subcategory_id], args[:expand_district_subcategories].present?)
    else
      # raise error?
    end

    # handle ages
    set_age_group(args[:age_group_id], args[:age_category_id]) # TODO fix this
  end

  def set_category(arg, use_district_categories)
    @category_type = :category

    klazz = use_district_categories ? DistrictCategory : Category
    @categories = Mod.create_filter(arg, klazz)
  end

  def set_subcategory(arg, expand_district_subcategories)
    subcategory_id = Mod.parse_value(arg)
    @category_type = :subcategory

    if @q.include_district_subcategories && expand_district_subcategories
      subcategories = subcategory_id == 'iterate_all' ?
        Subcategory.expanded : Subcategory.where(id: subcategory_id)
    elsif @q.include_district_subcategories
      subcategories = subcategory_id == 'iterate_all' ? Subcategory.compacted : Subcategory.where(id: subcategory_id)
    else
      subcategories = subcategory_id == 'iterate_all' ? InternalSubcategory.all : InternalSubcategory.where(id: subcategory_id)
    end

    sum_all = subcategory_id == 'sum_all'
    @categories = Filter.new(subcategories, sum_all)
  end
  #------------------------

  # currently, multiple as one is basically used as a flag to signal
  # whether the collection is an array to be iterated over, or a single item
  # needs improvement

  # special case. needs better, less fugly solution. but works for now
  def set_age_group(age_group_id, age_category_id)
    sum_all = age_group_id == 'sum_all' || age_category_id == 'sum_all'
    sum_multiple_as_one = false

    if age_category_id == 'none'
      categories = []
      age_groups = age_group_id == 'iterate_all' ? AgeGroup.all : AgeGroup.where(id: age_group_id)
      age_groups.each do |ag|
        categories << LineItem.new(ag.id, ag.name)
      end
    elsif age_category_id == 'iterate_all'
      categories = []
      AgeGroup.age_categories.each do |ag|
        label = AgeGroup.get_label(ag[0])
        id = AgeGroup.where(age_category: ag[1])
        categories << LineItem.new(id, label)
      end
    else
      label =  AgeGroup.get_label(age_category_id)
      id = AgeGroup.where(age_category: age_category_id)
      categories = LineItem.new(id, label)
      sum_multiple_as_one = true
    end

    @age_groups = Filter.new(categories, sum_all, sum_multiple_as_one)
  end


  # --------------------

  def get_visible_headers
    # :category_type, :categories, :maintypes, :subtypes, :age_groups, :results, :q, :headers

    headers = []
    headers << "maintype" unless @maintypes.sum_all
    headers << "subtype" unless @subtypes.sum_all
    headers << "category" unless @categories.blank? || @categories.sum_all
    headers << "subcategory" unless @subcategories.blank? || @subcategories.sum_all
    # headers << "agecategory" unless @age_category_id.blank? || @age_category_id == 'sum_all'
    headers << "agegroup" unless @age_groups.blank? || @age_groups.sum_all

    headers
  end


  #
  # -------------------
  #

  def get_results(headers)
    @headers = headers
    @results = []
    traverse_branches

    @results.flatten
  end

  def traverse_branches
    if @q.branches.sum_all
      traverse_maintypes(LineItem.new(nil, 'Samlet'))
    else
      @q.branches.collection.each do |branch|
        traverse_maintypes(LineItem.new(branch.id, branch.name))
      end
    end
  end

  def traverse_maintypes(branch)
    if @maintypes.sum_all
      traverse_subtypes(branch, LineItem.new(nil, 'Samlet'))
    else
      @maintypes.collection.each do |maintype|
        traverse_subtypes(branch, LineItem.new(maintype.id, maintype.label))
      end
    end
  end


  def traverse_subtypes(branch, maintype)
    if @subtypes.sum_all
      traverse_age_groups(branch, maintype, LineItem.new(nil, 'Samlet'))
    else
      @subtypes.collection.each do |subtype|
        next unless maintype.id == nil || subtype.associated?(maintype.id)

        traverse_age_groups(branch, maintype, LineItem.new(subtype.id, subtype.label))
      end
    end
  end

  def traverse_age_groups(branch, maintype, subtype)
    if @age_groups.sum_all
      traverse_categories(branch, maintype, subtype, LineItem.new(nil, 'Samlet'))
    elsif @age_groups.sum_multiple_as_one
      traverse_categories(branch, maintype, subtype, @age_groups.collection)
    else
      @age_groups.collection.each do |ag|
        traverse_categories(branch, maintype, subtype, ag)
      end
    end
  end


  def traverse_categories(branch, maintype, subtype, age_group)
    if @categories.sum_all
      events = get_events(branch.id, subtype_id: subtype.id, maintype_id: maintype.id, age_group_id: age_group.id)
      calculate_result(branch_name: branch.label, events: events, subtype: subtype.label, maintype: maintype.label, age_group: age_group.label)
    else @categories.collection.each do |cat|
      next unless cat.subtype_associated?(subtype.id) ||
      cat.maintype_associated?(maintype.id) ||(subtype.id.nil? && maintype.id.nil?)

      events = case @category_type
      when :category then get_events(branch.id, category_id: cat.id, subtype_id: subtype.id, maintype_id: maintype.id, age_group_id: age_group.id)
      when :subcategory then get_events(branch.id, subcategory_id: cat.id, subtype_id: subtype.id, maintype_id: maintype.id, age_group_id: age_group.id)
      end

      calculate_result(branch_name: branch.label, category_name: cat.name, events: events, subtype: subtype.label, maintype: maintype.label, age_group: age_group.label)
    end
  end
end


  # return value = {}
  def calculate_result(branch_name: 'Samlet', category_name: 'Samlet', events: nil,
    maintype: 'Samlet', subtype: 'Samlet', age_group: 'Samlet')

    young_ages_count = events.to_a.sum(&:sum_non_adults)
    all_ages_count = events.to_a.sum(&:sum_all_ages)
    older_ages_count = events.to_a.sum(&:sum_adults)

    # legg til events.non_adults.size
    # legg til header "Arr for barn/unge"
    # ny set metode include_subsize(truefalse)
    res = {}
    @headers.each do |header|
      res[header.id.to_sym] = @q.period_label if header.id == "period"
      res[header.id.to_sym] = branch_name if header.id == "branch_name"
      res[header.id.to_sym] = category_name if header.id == "category"
      res[header.id.to_sym] = category_name if header.id == "subcategory"
      res[header.id.to_sym] = maintype if header.id == "maintype"
      res[header.id.to_sym] = subtype if header.id == "subtype"
      res[header.id.to_sym] = age_group if header.id == "age_group"
      res[header.id.to_sym] = events.size if header.id == "no_of_events"
      res[header.id.to_sym] = all_ages_count if header.id == "no_of_attendants"
      res[header.id.to_sym] = age_group if header.id == "agegroup"
      # add more
    end

    #res[:link] = {from_date: @from_date, to_date: @to_date, label: @period_label, }
    # maybe better? :
    ##res[:link] = {this_query.to_json}


    @results << res
  end


  def get_events (branch_id = nil, category_id: nil, subcategory_id: nil, district_category_id: nil,
    maintype_id: nil, subtype_id: nil, age_group_id: nil)

    catz = @use_district_categories ? 'by_district_category' : 'by_category'

    Event.between_dates(@q.from_date, @q.to_date)
    .exclude_marked_events
    .by_branch(branch_id)
    .by_age_group(age_group_id)
    .by_maintype(maintype_id)
    .by_subtype(subtype_id)
    .by_subcategory(subcategory_id, @expand_district_subcategories)
    .send(catz, category_id)
  end

end
