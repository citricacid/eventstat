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
  belongs_to :age_group
  belongs_to :event_type
  belongs_to :branch
  belongs_to :category
  belongs_to :subcategory

  scope :reverse, -> { order('id').reverse_order }
  scope :order_by_event_date, -> { order(date: :desc) }
  scope :order_by_registration_date, -> { order(id: :desc) }
  scope :exclude_marked_events, -> { where(marked_for_deletion: 0) }

  validates :name, length: { minimum: 2, too_short: "Minimum %{count} tegn"}
  validates :date, presence: true


  def self.between_dates(from_date, to_date)
    where("date >= ? and date <= ?", from_date, to_date)
  end


  def self.by_branch(id)
    id.present? ? where("branch_id = ?", id) : all
  end

  def self.by_category(id) # and event_type = ????
    id.present? ? where("category_id = ?", id) : all
  end


  def self.by_subcategory(id)
    id.present? ? where("subcategory_id = ?", id) : all
  end

  def self.by_event_type(id)
    id.present? ? where("event_type_id = ?", id) : all
  end

  def self.by_subtype(id)
    #id.present? ? joins(:event_type).where('event_types.event_subtype_id' => id) : all
    id.present? ? joins(:event_type).where('event_types.event_subtype_id = ?', id) : all
  end


  def self.by_maintype(id)
    #id.present? ? joins(:event_type).where('event_types.event_maintype_id' => id) : all
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


class Branch < ActiveRecord::Base
  has_many :events
  has_many :counts, :through => :events

  default_scope { order(:name => :asc) }

  def set_lock(date)
    # check if valid...
    locked_until = date # if locked_until < date
    save!
  end

end



class AgeGroup < ActiveRecord::Base
  default_scope { order(:view_priority => :asc) }
  enum age_category: { adult: 0, non_adult: 1 }

  def self.get_label(enum_key)
    if enum_key == 'adult'
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
    categories.map {|category| category.subcategories.pluck(:id)}.flatten
  end

end


class EventSubtype < ActiveRecord::Base
  has_one :event_type
  has_many :categories
  has_many :subcategories, through: :categories

  def associated?(maintype_id)
    event_type.event_maintype.id == maintype_id
  end

  def label
    I18n.t("subtype.#{name}").capitalize
  end

  def category_ids
    categories.pluck(:id)
  end

  def subcategory_ids
    categories.map {|category| category.subcategories.pluck(:id)}.flatten
  end

end



class Category < ActiveRecord::Base
  has_many :subcategory_links
  has_many :subcategories, through: :subcategory_links

  belongs_to :event_maintype
  belongs_to :event_subtype


  def subcategory_associated?(subcategory_id)
      subcategories.pluck(:id).include?(subcategory_id)
  end

  def maintype_associated?(maintype_id)
    event_maintype.id == maintype_id
  end

  # rename to properly identify function
  def subtype_associated?(subtype_id, maintype_id)
    (event_subtype && event_subtype.id == subtype_id) || (event_subtype == nil && event_maintype.id == maintype_id )
  end

end


class Subcategory < ActiveRecord::Base
  has_many :subcategory_links
  has_many :categories, through: :subcategory_links

  default_scope { order(:view_priority => :asc) }

  def maintype_associated?(maintype_id)
    categories.map {|cat| cat.maintype_associated?(maintype_id)}.present?
  end

  def subtype_associated?(subtype_id, maintype_id)
    categories.map {|cat| cat.subtype_associated?(subtype_id, maintype_id)}.present?
  end


end

class SubcategoryLink < ActiveRecord::Base
  belongs_to :subcategory
  belongs_to :category

end
