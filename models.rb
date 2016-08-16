# encoding: utf-8

require 'date'
require 'active_record'

require 'i18n'
require 'i18n/backend/fallbacks'

I18n.available_locales = [:nb, :en]
I18n.default_locale = :nb
I18n.locale = :nb

I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
I18n.load_path = Dir['config/locales/*.yml']



class Event < ActiveRecord::Base
  has_many :counts
  belongs_to :event_type
  belongs_to :branch
  belongs_to :subcategory

  scope :reverse, -> { order('id').reverse_order }

  validates :name, length: { minimum: 2, too_short: "Minimum %{count} tegn"}
  validates :date, presence: true


  def self.between_dates(from_date, to_date)
    where("date >= ? and date <= ?", from_date, to_date)
  end


  def self.by_branch(id)
    id.present? ? where(branch_id: id) : all
  end


  def self.by_category(id)
    id.present? ? joins(:subcategory).where('subcategories.category_id' => id) : all
  end


  def self.by_subcategory(id)
    id.present? ? where(subcategory_id: id) : all
  end

  def self.by_event_type(id)
    id.present? ? where(event_type_id: id) : all
  end

  def self.by_subtype(id)
    id.present? ? joins(:event_type).where('event_types.event_subtype_id' => id) : all
  end


  def self.by_maintype(id)
    id.present? ? joins(:event_type).where('event_types.event_maintype_id' => id) : all
  end

  def sum_all_ages
    counts.sum(:attendants)
  end


  def sum_young_ages
    counts.select(&:is_young).sum(&:attendants)
  end

  def sum_older_ages
    counts.select(&:is_older).sum(&:attendants)
  end

end


class Branch < ActiveRecord::Base
  has_many :events
  has_many :counts, :through => :events
end



class AgeGroup < ActiveRecord::Base
  has_one :count
  belongs_to :age_category

  def is_young
    age_category.is_young
  end

end


# kan med fordel erstattes med enum, i think
class AgeCategory < ActiveRecord::Base
    def is_young
      id == 2
    end

end

class EventType < ActiveRecord::Base
  belongs_to :event_maintype
  belongs_to :event_subtype

end

class EventMaintype < ActiveRecord::Base
  has_many :event_types

  def self.has_categories(id)
    find(id).name == 'event'
  end
end

class EventSubtype < ActiveRecord::Base
  has_one :event_type

  def connected?(maintype_id)
    event_type.event_maintype.id == maintype_id
  end

  def label
    I18n.t("subtype.#{name}").capitalize
  end
end



class Count < ActiveRecord::Base
  belongs_to :event
  belongs_to :age_group

  validates :attendants, numericality: {only_integer: true, greater_than: 0}


  def is_young
    age_group.is_young
  end

  def is_older
    !age_group.is_young
  end

  def self.sum_all_ages
    sum(:attendants)
  end

  def self.sum_young_ages
    sum(:attendants)
  end

end


class Category < ActiveRecord::Base
  has_many :subcategories
end


class Subcategory < ActiveRecord::Base
  belongs_to :category
end


class Group < ActiveRecord::Base
  enum status: { event: 0, exhibition: 1 }
end





class ReportBuilder
  def initialize
    @report = Report.new
  end

  def set_dates(from_date, to_date)
    @report.from_date = from_date
    @report.to_date = to_date
  end


  def set_branch(branch_id)
    @report.sum_all_branches = branch_id == 'sum_all'
    @report.branches = branch_id == 'iterate_all' ? Branch.all : Branch.where(id: branch_id)
  end

  def set_category(category_id, subcategory_id)
    @report.sum_all_categories = category_id == 'sum_all' || subcategory_id == 'sum_all'
    @report.category_type = category_id != 'none' ? :category : :subcategory

    if @report.category_type == :category
      @report.categories = category_id == 'iterate_all' ? Category.all : Category.where(id: category_id)
    else
      @report.categories = subcategory_id == 'iterate_all' ? Subcategory.all : Subcategory.where(id: subcategory_id)
    end
  end

  def set_type(maintype_id, subtype_id)

    sum_all_maintypes = maintype_id == 'sum_all'
    maintypes = maintype_id == 'iterate_all' ? EventMaintype.all : EventMaintype.where(id: maintype_id)

    @report.sum_all_maintypes = maintype_id == 'sum_all'
    @report.maintypes = maintype_id == 'iterate_all' ? EventMaintype.all : EventMaintype.where(id: maintype_id)
    #@report.maintypes = nil if maintype_id == 'sum_all'

    @report.sum_all_subtypes = subtype_id == 'sum_all'
    @report.subtypes = subtype_id == 'iterate_all' ? EventSubtype.all : EventSubtype.where(id: subtype_id)

  end


  def report
    obj = @report.dup
    @report = Report.new
    return obj
  end

end



TypeConfig = Struct.new(:collection, :sum_all)


class Report
  attr_accessor :from_date, :to_date, :sum_all_branches, :sum_all_categories,
  :branches, :categories, :category_type, :maintypes, :sum_all_maintypes,
  :subtypes, :sum_all_subtypes, :baz

  Foo = Struct.new(:id, :label)

  def get_results
    @results = []
    traverse_maintypes

    {results: @results.flatten}.to_json
  end


  def traverse_maintypes
    if @sum_all_maintypes
      traverse_subtypes(Foo.new(nil, 'Samlet'))
    else
      @maintypes.each do |maintype|
        traverse_subtypes(Foo.new(maintype.id, maintype.label))
      end
    end
  end


  def traverse_subtypes(maintype)
    if @sum_all_subtypes
      traverse_branches(maintype, Foo.new(nil, 'Samlet'))
    else
      @subtypes.each do |subtype|
        traverse_branches(maintype, Foo.new(subtype.id, subtype.label)) if maintype.id == nil || subtype.connected?(maintype.id)
      end
    end
  end


  def traverse_branches(maintype, subtype)
    if @sum_all_branches
      traverse_categories(maintype, subtype, Foo.new(nil, 'Samlet'))
    else
      @branches.each do |branch|
        traverse_categories(maintype, subtype, Foo.new(branch.id, branch.name))
      end
    end
  end


  def traverse_categories(maintype, subtype, branch)
    if @sum_all_categories
      events = get_events(branch.id, subtype_id: subtype.id, maintype_id: maintype.id)
      calculate_result(branch_name: branch.label, events: events, subtype: subtype.label, maintype: maintype.label)
    else @categories.each do |cat|
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
  young_ages_count = events.to_a.sum(&:sum_young_ages)
  all_ages_count = events.to_a.sum(&:sum_all_ages)
  older_ages_count = events.to_a.sum(&:sum_older_ages)

  @results << {branch_name: branch_name, category_name: category_name, all: all_ages_count,
    young: young_ages_count, older: older_ages_count, no_of_events: events.size,
    maintype: maintype, subtype: subtype}
  end


  def get_events (branch_id = nil, category_id: nil, subcategory_id: nil,
    maintype_id: nil, subtype_id: nil)

    Event.between_dates(@from_date, @to_date)
    .by_maintype(maintype_id)
    .by_subtype(subtype_id)
    .by_branch(branch_id)
    .by_category(category_id)
    .by_subcategory(subcategory_id)
  end

end
