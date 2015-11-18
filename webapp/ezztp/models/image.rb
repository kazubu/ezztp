class Image < ActiveRecord::Base
  before_destroy :check_before_destroy
  has_many :devices, :dependent => :destroy
  validates_associated :devices
  validates_uniqueness_of :file_name, :case_sensitive => false

  validates_presence_of :model, :version, :file_name

  private

  def check_before_destroy
    puts "Devices: #{devices}"
    return if devices.blank?

    # Cannot delete Image which has one or more devices
    return false
  end
end
