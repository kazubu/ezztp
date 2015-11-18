class ConfigurationTemplate < ActiveRecord::Base
  before_destroy :check_before_destroy
  has_many :devices, :dependent => :destroy
  validates_associated :devices
  validates_uniqueness_of :name, :case_sensitive => false

  validates_presence_of :name, :template

  private

  def check_before_destroy
    if name == "default"
      # Cannot delete default template
      return false
    end

    puts "Devices: #{devices}"
    return if devices.blank?

    # Cannot delete Template which has one or more devices
    return false
  end
end
