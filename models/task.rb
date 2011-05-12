class Task < ActiveRecord::Base
  has_and_belongs_to_many :tags
  
  serialize :details, Array
  
  def describe(text)
    self.details = [] unless self.details
    self.details << [text, Time.now]
    save
  end
  
  def by_tag_name(tag_name)
    return Tag.find_by_name(tag_name).tasks
  end
end