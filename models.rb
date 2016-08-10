# encoding: utf-8

require 'date'
require 'active_record'


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


  def sum_all_ages
    counts.sum(:attendants)
  end


  def sum_young_ages
    counts.select(&:is_young).sum(&:attendants)
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

end

class EventSubtype < ActiveRecord::Base
  has_many :event_types

end





class Count < ActiveRecord::Base
  belongs_to :event
  belongs_to :age_group

  validates :attendants, numericality: {only_integer: true, greater_than: 0}


  def is_young
    age_group.is_young
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
