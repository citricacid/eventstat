# encoding: utf-8
require 'csv'

class ReportBuilder
  def initialize
    @report = Report.new
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


  def set_type(maintype_id, subtype_id)
    sum_all = maintype_id == 'sum_all'
    maintypes = maintype_id == 'iterate_all' ? EventMaintype.all : EventMaintype.where(id: maintype_id)
    @report.maintypes = Filter.new(maintypes, sum_all)

    sum_all_subtypes = subtype_id == 'sum_all'
    subtypes = subtype_id == 'iterate_all' ? EventSubtype.all : EventSubtype.where(id: subtype_id)
    @report.subtypes = Filter.new(subtypes, sum_all_subtypes)
  end


  def report
    obj = @report.dup
    @report = Report.new
    return obj
  end

end



Filter = Struct.new(:collection, :sum_all)
Foo = Struct.new(:id, :label) # TODO FIX ME

class Report
  attr_accessor :from_date, :to_date, :branches, :categories, :category_type, :maintypes, :subtypes

  def get_results
    @results = []
    traverse_branches

    puts @results.inspect # delete

    attributes = %w{id email name}

    # remove this
    csv_string = CSV.generate(headers: true) do |csv|
      csv << attributes

      @results.flatten.each do |row|
        csv << row.values
      end
    end

    puts csv_string


    {results: @results.flatten}.to_json
  end


  def traverse_branches
    if @branches.sum_all
      traverse_maintypes(Foo.new(nil, 'Samlet'))
    else
      @branches.collection.each do |branch|
        traverse_maintypes(Foo.new(branch.id, branch.name))
      end
    end
  end


  def traverse_maintypes(branch)
    if @maintypes.sum_all
      traverse_subtypes(branch, Foo.new(nil, 'Samlet'))
    else
      @maintypes.collection.each do |maintype|
        traverse_subtypes(branch, Foo.new(maintype.id, maintype.label))
      end
    end
  end


  def traverse_subtypes(branch, maintype)
    if @subtypes.sum_all
      traverse_categories(branch, maintype, Foo.new(nil, 'Samlet'))
    else
      @subtypes.collection.each do |subtype|
        next unless maintype.id == nil || subtype.associated?(maintype.id)

        traverse_categories(branch, maintype, Foo.new(subtype.id, subtype.label))
      end
    end
  end


  def traverse_categories(branch, maintype, subtype)
    if @categories.sum_all
      events = get_events(branch.id, subtype_id: subtype.id, maintype_id: maintype.id)
      calculate_result(branch_name: branch.label, events: events, subtype: subtype.label, maintype: maintype.label)
    else @categories.collection.each do |cat|
      next unless cat.subtype_associated?(subtype.id, maintype.id) ||
       (subtype.id == nil && cat.maintype_associated?(maintype.id)) ||
       (subtype.id == nil && maintype.id == nil)

      events = case @category_type
        when :category then get_events(branch.id, category_id: cat.id, subtype_id: subtype.id, maintype_id: maintype.id)
        when :subcategory then get_events(branch.id, subcategory_id: cat.id, subtype_id: subtype.id, maintype_id: maintype.id)
      end

      calculate_result(branch_name: branch.label, category_name: cat.name,
      events: events, subtype: subtype.label, maintype: maintype.label)
    end
  end

end


def calculate_result(branch_name: 'Samlet', category_name: 'Samlet', events: nil,
  maintype: 'Samlet', subtype: 'Samlet')
  young_ages_count = events.to_a.sum(&:sum_non_adults)
  all_ages_count = events.to_a.sum(&:sum_all_ages)
  older_ages_count = events.to_a.sum(&:sum_adults)

  @results << {branch_name: branch_name, category_name: category_name, all: all_ages_count,
    young: young_ages_count, older: older_ages_count, no_of_events: events.size,
    maintype: maintype, subtype: subtype}
  end


  def get_events (branch_id = nil, category_id: nil, subcategory_id: nil,
    maintype_id: nil, subtype_id: nil)
    puts "maintype: " + maintype_id.to_s
    puts "subtype: " + subtype_id.to_s
    puts "kategori: " + category_id.to_s
    Event.between_dates(@from_date, @to_date)
    .by_branch(branch_id)
    .by_maintype(maintype_id)
    .by_subtype(subtype_id)
    .by_category(category_id)
    .by_subcategory(subcategory_id)
  end

end
