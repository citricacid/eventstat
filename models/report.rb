# encoding: utf-8
require 'csv'


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
# :is_counntable - boolean flag indicating whether the column values should be accumulated
HeaderItem = Struct.new(:label, :id, :is_countable)


#
# ReportBuilder
#
# Setters for defining the filters for the final report.
#
# Parameters: The id parameters can have the following values:
# 'iterate_all' - report will iterate over all existing items (one lite item for each)
# 'sum_all' - all existing items will be lumped as one
# 'none' - for mutually exclusive categories...
# single id or list of id values

# idea: get_headers_for(...) and get_default_headers() - but where to place them?

class ReportBuilder
  def initialize
    @report = Report.new
  end

  def report
    obj = @report.dup
    @report = Report.new
    return obj
  end

  def build
    @report.headers = build_headers
    return report
  end

  def build_headers
    headers = []

    # fixed headers
    headers << HeaderItem.new("Periode", "period", false)
    headers << HeaderItem.new("Sted", "branch_name", false)

    # dynamic headers
    headers << HeaderItem.new("Type", "maintype", false) unless @report.maintypes.sum_all
    headers << HeaderItem.new("Undertype", "subtype", false) unless @report.subtypes.sum_all
    headers << HeaderItem.new("Kategori", "category", false) unless @report.categories.sum_all || @report.category_type == :subcategory
    headers << HeaderItem.new("Underkategori", "subcategory", false) unless @report.categories.sum_all || @report.category_type == :category
    headers << HeaderItem.new("Alder", "agecategory", false) unless @report.age_categories.nil? || @report.age_categories.sum_all
    headers << HeaderItem.new("Alder", "agegroup", false) unless @report.age_groups.nil? || @report.age_groups.sum_all

    # fixed, countable headers
    headers << HeaderItem.new("Ant. deltagere", "no_of_attendants", true)
    headers << HeaderItem.new("Ant. arr", "no_of_events", true)

    headers.flatten
  end


  #
  # Setters
  #
  def set_strategy(key)
    @report.strategy = key
  end

  def set_period_label(str)
    @report.period_label = str
  end

  def set_dates(from_date, to_date)
    @report.from_date = from_date
    @report.to_date = to_date
  end

  def set_branch(branch_id)
    sum_all = branch_id == 'sum_all'
    branches = branch_id == 'iterate_all' ? Branch.all : Branch.where(id: branch_id)
    @report.branches = Filter.new(branches, sum_all)
  end

  # refactor into set_category and set_subcategory

  def set_category(category_id, subcategory_id)
    @report.category_type = category_id != 'none' ? :category : :subcategory

    sum_all = category_id == 'sum_all' || subcategory_id == 'sum_all'

    if @report.category_type == :category
      categories = category_id == 'iterate_all' ? Category.all : Category.where(id: category_id)
    else
      categories = subcategory_id == 'iterate_all' ? Subcategory.all : Subcategory.where(id: subcategory_id)
    end

    @report.categories = Filter.new(categories, sum_all)
  end


  def set_maintype(maintype_id)
    sum_all = maintype_id == 'sum_all'
    maintypes = maintype_id == 'iterate_all' ? EventMaintype.all : EventMaintype.where(id: maintype_id)
    @report.maintypes = Filter.new(maintypes, sum_all)
  end

  def set_subtype(subtype_id)
    sum_all_subtypes = subtype_id == 'sum_all'
    subtypes = subtype_id == 'iterate_all' ? EventSubtype.all : EventSubtype.where(id: subtype_id)
    @report.subtypes = Filter.new(subtypes, sum_all_subtypes)
  end


  # special case. needs better, less fugly solution. but works for now
  def set_age_group(age_group_id, age_category_id)
    sum_all = age_group_id == 'sum_all' || age_category_id == 'sum_all'
    sum_multiple_as_one = nil

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
      #categories = age_category_id == 'iterate_all' ? AgeGroup.age_categories : AgeGroup.where(age_category: age_category_id)
      label =  AgeGroup.get_label(age_category_id)
      id = AgeGroup.where(age_category: age_category_id)
      categories = LineItem.new(id, label)
      sum_multiple_as_one = true
    end

    @report.age_groups = Filter.new(categories, sum_all, sum_multiple_as_one)
  end
end




# Report
#
#

class Report
  attr_accessor :period_label, :from_date, :to_date, :branches, :categories, :category_type,
  :maintypes, :subtypes, :age_groups, :age_categories, :headers, :strategy

  def get_results
    @results = []
    traverse_branches

    {headers: @headers.flatten, results: @results.flatten}.to_json
  end

  def traverse_branches
    if @branches.sum_all
      traverse_maintypes(LineItem.new(nil, 'Samlet'))
    else
      @branches.collection.each do |branch|
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
    elsif @age_groups.sum_multiple_as_one == true
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
      next unless cat.subtype_associated?(subtype.id, maintype.id) ||
      (subtype.id == nil && cat.maintype_associated?(maintype.id)) ||
      (subtype.id == nil && maintype.id == nil)

      events = case @category_type
      when :category then get_events(branch.id, category_id: cat.id, subtype_id: subtype.id, maintype_id: maintype.id, age_group_id: age_group.id)
      when :subcategory then get_events(branch.id, subcategory_id: cat.id, subtype_id: subtype.id, maintype_id: maintype.id, age_group_id: age_group.id)
      end

      calculate_result(branch_name: branch.label, category_name: cat.name,
      events: events, subtype: subtype.label, maintype: maintype.label, age_group: age_group.label)
    end
  end

end


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
    res[header.id.to_sym] = @period_label if header.id == "period"
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

  @results << res
end




def get_events (branch_id = nil, category_id: nil, subcategory_id: nil,
  maintype_id: nil, subtype_id: nil, age_group_id: nil)
  Event.between_dates(@from_date, @to_date)
  .exclude_marked_events
  .by_branch(branch_id)
  .by_age_group(age_group_id)
  .by_maintype(maintype_id)
  .by_subtype(subtype_id)
  .by_category(category_id)
  .by_subcategory(subcategory_id)
end

end
