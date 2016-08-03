# encoding: utf-8

require 'date'
require 'active_record'


class Event < ActiveRecord::Base
  has_many :counts
  belongs_to :branch
  belongs_to :genre

  validates :title, length: { minimum: 2, too_short: "Minimum %{count} tegn"}
  validates :date, presence: true

  def self.between_dates(from_date, to_date)
    where("date >= ? and date <= ?", from_date, to_date)
  end


  def self.by_branch(id)
    return all unless id.present?
    where("branch_id = ?", id)
  end


  def self.by_genre(id)
    return all unless id.present?
    where("genre_id = ?", id)
  end

end


class Branch < ActiveRecord::Base
  has_many :events
  has_many :counts, :through => :events
end



class AgeGroup < ActiveRecord::Base

end



class AgeCategory < ActiveRecord::Base

end





class Count < ActiveRecord::Base
  belongs_to :event
  has_many :agegroups

  validates :attendants, numericality: {only_integer: true, greater_than: 0}

  def self.sum_all_ages
    where("category_id > ?", 0).sum(:attendants)
  end

  def self.sum_young_ages
    where("category_id > ?", 1).sum(:attendants)
  end

end



class Subcategory < ActiveRecord::Base

end
