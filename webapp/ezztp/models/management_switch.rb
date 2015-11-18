class ManagementSwitch < ActiveRecord::Base
  validates_uniqueness_of :name, :case_sensitive => false
  validates_uniqueness_of :subscriber_id, :case_sensitive => false
  validates_presence_of :name, :subscriber_id
end
