# encoding: utf-8

require 'date'
require 'active_record'


class Event < ActiveRecord::Base
  has_many :counts
  belongs_to :branch
  belongs_to :genre

  validates :title, length: { minimum: 2, too_short: "Minimum %{count} tegn"}
  validates :title, :date, presence: true
  #validates presence of counts


end


class Branch < ActiveRecord::Base

end




class Category < ActiveRecord::Base


end



class Count < ActiveRecord::Base
  belongs_to :event
  has_many :categories

  validates :attendants, numericality: {only_integer: true, greater_than: 0}
end



class Genre < ActiveRecord::Base

end
