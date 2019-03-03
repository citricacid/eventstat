# encoding: utf-8

require 'date'
require 'active_record'


#require 'logger'
#ActiveRecord::Base.logger = Logger.new(STDOUT)

class Query < ActiveRecord::Base
  has_many :query_parameters

  def as_json(options={})
      super.as_json(options).merge({query_elements: query_elements})
  end
end

class QueryParameter < ActiveRecord::Base
  belongs_to :query
end

class CompoundQuery < ActiveRecord::Base
  has_many :compound_query_links
  has_many :queries, through: :compound_query_links
end

class CompoundQueryLink < ActiveRecord::Base
  belongs_to :query
  belongs_to :compound_query
end


class Event < ActiveRecord::Base
  belongs_to :age_group
  belongs_to :event_type
  belongs_to :branch
  belongs_to :category
  belongs_to :subcategory
  #belongs_to :internal_subcategory, foreign_key: 'subcategory_id'
  #belongs_to :district_subcategory, foreign_key: 'district_subcategory_id'
  belongs_to :district_category

  scope :order_by_reverse_id, -> { order('id').reverse_order }
  scope :order_by_event_date, -> { order(date: :desc) }
  scope :order_by_registration_date, -> { order(id: :desc) }
  scope :exclude_marked_events, -> { where(marked_for_deletion: 0) }
  
  scope :sans_excluded_branches, -> { where.not(branch_id: [1]) }


  # TODO: more validations
  validates :name, length: { minimum: 2, too_short: "Minimum %{count} tegn"}
  validates :date, :attendants, :age_group_id, presence: true
  #validates :

  #validate :matching_aggregated_sub

  def matching_aggregated_sub
    errors.add(:aggregated_subcategory_id, "is not set") if subcategory.is_a(DistrictSubcategory) &&
      (aggregated_subcategory_id.blank? || aggregated_subcategory_id != branch.aggregated_subcategory_id)
  end


  def self.between_dates(from_date, to_date)
    where("date >= ? and date <= ?", from_date, to_date)
  end

  # TODO
  # def self.on_weekdays(days)
  #  where ()
  # end

  def self.by_branch(id)
    id.present? ? where("branch_id = ?", id) : all
  end

  def self.by_category(id) # and event_type = ????
    id.present? ? where("category_id = ?", id) : all
  end

  def self.by_district_category(id)
    id.present? ? where("district_category_id = ?", id) : all
  end

  def self.by_subcategory(id, expand = true)
    if id.present? && !expand && Subcategory.find(id).is_a?(AggregatedSubcategory)
      where("aggregated_subcategory_id = ?", id)
    else
      id.present? ? where("subcategory_id = ?", id) : all
    end
  end

  def self.by_event_type(id)
    id.present? ? where("event_type_id = ?", id) : all
  end

  def self.by_subtype(id)
    id.present? ? joins(:event_type).where('event_types.event_subtype_id = ?', id) : all
  end

  def self.by_maintype(id)
    id.present? ? joins(:event_type).where('event_types.event_maintype_id = ?', id) : all
  end

  def self.by_age_group(id)
    id.present? ? where(age_group_id: id) : all
  end

  def self.by_age_category_id(group_id)
    group_id.present? ? joins(:age_group).where('age_groups.age_category = ?', group_id) : all
  end

  def self.by_age_category(group)
    if group.present?
      id = group == 'adult' ? 0 : 1
      joins(:age_group).where('age_groups.age_category = ?', id)
    else
      all
    end
  end

  def self.search(text)
    joins(:subcategory).where('subcategories.name LIKE ?', "%#{text}%").or(joins(:subcategory).where('events.name LIKE ?', "%#{text}%"))
  end

  def sum_all_ages
    attendants
  end


  def sum_non_adults
    age_group.non_adult? ? attendants : 0
  end

  def sum_adults
    #counts.select(&:is_older).sum(&:attendants)
    age_group.adult? ? attendants : 0
  end

end


class Template < ActiveRecord::Base
  belongs_to :age_group
  belongs_to :event_type
  belongs_to :branch
  belongs_to :category
  belongs_to :subcategory
  belongs_to :district_category
end



class Branch < ActiveRecord::Base
  has_many :events
  has_many :counts, :through => :events
  has_many :templates

  has_many :district_links
  has_many :district_categories, through: :district_links
  has_many :district_subcategories, through: :district_links, source: 'DistrictSubcategory'

  default_scope { order(:name => :asc) }

  def has_templates?
    templates.count > 0
  end

  def self.activate_lock(branch_id, date)
    begin
      lock_date = Date.parse(date)
      find(branch_id).set_lock(lock_date)
    rescue ArgumentError => e
      e.message
    rescue ActiveRecord::RecordNotFound => e
      e.message
    end
  end


  def set_lock(to_date)
    from_date = locked_until.next_day #TODO fix this
    lock_events = events.where("date >= ? and date <= ?", from_date, to_date)

    success = false
    ActiveRecord::Base.transaction do
      lock_events.each do |event|
        if event.marked_for_deletion == 1
          event.destroy!
        else
          event.is_locked = 1
          event.save!
        end
      end

      self.locked_until = to_date
      save!
      success = true
    end

    success
  end

end



class AgeGroup < ActiveRecord::Base
  default_scope { order(:view_priority => :asc) }
  enum age_category: { adult: 0, non_adult: 1 }

  def self.get_label(enum_key)
    if enum_key == 'adult' || enum_key == "0"
      'voksne/alle'
    else
      'barn/unge'
    end
  end

end


class AgeAttribute < ActiveRecord::Base
  belongs_to :event_type
  belongs_to :age_group
end



class EventType < ActiveRecord::Base
  belongs_to :event_maintype
  belongs_to :event_subtype

  has_many :age_attributes

  default_scope { order(:view_priority => :asc) }
  scope :ordered_view, -> { joins(:event_maintype).order('event_maintypes.view_priority') }

  def age_group_ids
    age_attributes.map {|attribute| attribute.age_group_id}.flatten
  end

  # TODO: cleanup
  def get_category_id_by(subcategory_id)
    supercat = nil # rename this
    categories =   event_subtype.categories.present? ? event_subtype.categories : event_maintype.categories
    categories.each do |cat|
      if cat.subcategory_associated?(subcategory_id)
        supercat = cat
      end
    end
    supercat
  end

  def is_linked?(subcategory_id)
    subcategory_ids.include?(subcategory_id)
  end

  def category_ids
    event_subtype.categories.present? ? event_subtype.category_ids : event_maintype.category_ids
  end


  def subcategory_ids
    event_subtype.subcategory_ids.present? ? event_subtype.subcategory_ids : event_maintype.subcategory_ids
  end

end


class EventMaintype < ActiveRecord::Base
  has_many :event_types
  has_many :categories
  has_many :subcategories, through: :categories

  scope :ordered_view, -> { order('view_priority') }

  def event_subtype_ids
    subtype_ids = []
    EventSubtype.all.each do |type|
      subtype_ids << type.id if type.associated?(id)
    end
    subtype_ids
  end

  def category_ids
    categories.pluck(:id)
  end

  def subcategory_ids
    categories.map {|category| category.subcategories.where(type: 'InternalSubcategory').pluck(:id)}.flatten
    #categories.map {|category| category.subcategories.pluck(:id)}.flatten
  end

end


class EventSubtype < ActiveRecord::Base
  has_one :event_type
  has_many :categories
  has_many :subcategories, through: :categories

  def associated?(maintype_id)
    event_type.event_maintype.id == maintype_id
  end

  def category_ids
    categories.pluck(:id)
  end

  # TODO DONT LET THIS CODE PUBLISH WITHOUT PROPER TESTING
  def subcategory_ids
    categories.map {|category| category.subcategories.where(type: 'InternalSubcategory').pluck(:id)}.flatten
    #categories.map {|category| category.subcategories.pluck(:id)}.flatten
  end

  def internal_subcategory_ids
    categories.map {|category| category.subcategories.where(type: 'InternalSubcategory').pluck(:id)}.flatten
  end

end



class Category < ActiveRecord::Base
  has_many :subcategory_links
  has_many :subcategories, through: :subcategory_links

  belongs_to :event_maintype
  belongs_to :event_subtype


  def subcategory_associated?(subcategory_id)
      subcategories.pluck(:id).include?(subcategory_id.to_i)
  end

  def maintype_associated?(maintype_id)
    event_maintype && event_maintype.id == maintype_id.to_i
  end

  def subtype_associated?(subtype_id)
    event_subtype && event_subtype.id == subtype_id.to_i
  end

end


class Subcategory < ActiveRecord::Base
  has_many :subcategory_links
  has_many :categories, through: :subcategory_links

  has_one :aggregated_link
  has_one :aggregated_subcategory, through: :aggregated_link

  default_scope { order(:view_priority => :asc) }

  def self.internal
    where(type: 'InternalSubcategory')
  end

  def self.expanded
    where(type: 'DistrictSubcategory').or(where(type: 'InternalSubcategory'))
  end

  scope :compacted, -> { where(type: 'AggregatedSubcategory').or(where(type: 'InternalSubcategory')) }

  def maintype_associated?(maintype_id)
    categories.select {|cat| cat.maintype_associated?(maintype_id)}.present?
  end

  def subtype_associated?(subtype_id)
    categories.select {|cat| cat.subtype_associated?(subtype_id)}.present?
  end

  def aggregated_subcategory_id
    aggregated_subcategory&.id || nil
  end


end

class InternalSubcategory < Subcategory

end

class DistrictSubcategory < Subcategory

end

class AggregatedSubcategory < Subcategory
  has_many :aggregated_links
  has_many :subcategories, through: :aggregated_links
end

class SubcategoryLink < ActiveRecord::Base
  belongs_to :subcategory
  belongs_to :category
end


class DistrictLink < ActiveRecord::Base
  belongs_to :district_subcategory, foreign_key: 'subcategory_id'
  belongs_to :district_category
end

class AggregatedLink < ActiveRecord::Base
  belongs_to :aggregated_subcategory
  belongs_to :subcategory
end


class DistrictCategory < ActiveRecord::Base
  belongs_to :branch
  has_many :district_links
  has_many :district_subcategories, through: :district_links

  def subcategory_associated?(subcategory_id)
      district_subcategories.pluck(:id).include?(subcategory_id)
  end

  def maintype_associated?(maintype_id) #TODO fix?
    #event_maintype.id == maintype_id
    true
  end

  def subtype_associated?(subtype_id)
    #(event_subtype && event_subtype.id == subtype_id) || (event_subtype == nil && event_maintype.id == maintype_id )
    true
  end


  def district_subcategory_ids
    district_subcategories.pluck(:id)
  end
end
