# encoding: utf-8

require 'date'
require 'active_record'


class Event < ActiveRecord::Base
  has_one :genre
  has_many :counts


end


class Category < ActiveRecord::Base


end



class Count < ActiveRecord::Base
  belongs_to :event
  has_many :categories

end



class Genre < ActiveRecord::Base


end
