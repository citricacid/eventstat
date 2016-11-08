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
    id.present? ? joins(:subcategory).where(subcategories: {category_id: id}) : all
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
end



class AgeGroup < ActiveRecord::Base
  enum age_category: { adult: 0, non_adult: 1 }

end



class AgeAttribute < ActiveRecord::Base
  belongs_to :event_type
  belongs_to :age_group

end



class EventType < ActiveRecord::Base
  belongs_to :event_maintype
  belongs_to :event_subtype

  has_many :age_attributes

  scope :ordered_view, -> { joins(:event_maintype).order('event_maintypes.view_priority').reverse_order }

  def age_group_ids
    age_attributes.map {|attribute| attribute.age_group_id}.flatten
  end


  def category_ids
    event_subtype.categories.present? ? event_subtype.category_ids : event_maintype.category_ids
  end


  def subcategory_ids
    event_subtype.subcategory_ids.present? ? event_subtype.subcategory_ids : event_maintype.subcategory_ids
  end

  # NEW
  def linked_subcategory_ids
    subcats = event_subtype.subcategory_link_ids.present? ? event_subtype.subcategory_link_ids : event_maintype.subcategory_link_ids
    subcats.map {|subcategory| subcategory}.flatten
  end

end


class EventMaintype < ActiveRecord::Base
  has_many :event_types
  has_many :categories
  has_many :subcategories, through: :categories
  has_many :subcategory_links, through: :categories

  scope :ordered_view, -> { order('view_priority').reverse_order }

  def category_ids
    categories.pluck(:id)
  end


  def subcategory_ids
    categories.map {|category| category.subcategory_ids}.flatten
  end

  def subcategory_link_ids
    categories.map {|category| category.subcategory_link_ids}.flatten
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
    categories.map {|category| category.subcategory_ids}.flatten
  end

  def subcategory_link_ids
    categories.map {|category| category.subcategory_link_ids}.flatten
  end

end



class Category < ActiveRecord::Base
  has_many :subcategories
  has_many :subcategory_links

  belongs_to :event_maintype
  belongs_to :event_subtype

  # todo: replace with delegate
  def type_name
    event_maintype.name
  end

  def maintype_associated?(maintype_id)
    event_maintype.id == maintype_id
  end

  # rename to properly identify function
  def subtype_associated?(subtype_id, maintype_id)
    (event_subtype && event_subtype.id == subtype_id) || (event_subtype == nil && event_maintype.id == maintype_id )
  end

  def subcategory_ids
    subcategories.pluck(:id)
  end

  # TODO rename
  def subcategory_link_ids
    subcategory_links.pluck(:subcategory_id)
  end


end


class Subcategory < ActiveRecord::Base
  belongs_to :category

  delegate :type_name, :maintype_associated?, :subtype_associated?, :to => :category, :allow_nil => true

end

class SubcategoryLink < ActiveRecord::Base
  belongs_to :subcategory

  delegate :name, :definition, :subtype_associated?, :type_name, :to => :subcategory, :allow_nil => true

end
