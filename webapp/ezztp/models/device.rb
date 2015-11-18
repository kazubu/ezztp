class Device < ActiveRecord::Base
  belongs_to              :configuration_template
  belongs_to              :image
  validates_presence_of   :keytype, :key
  validates_format_of     :keytype, :with => /mac|serial|port|model/
  validates_uniqueness_of :key, :case_sensitive => false

  validates_format_of     :key, with: /\A[a-f0-9]{12}\Z/, if: :key_is_mac?
  validates_format_of     :key, with: /\A[A-Z][A-Z][0-9]{10}\Z/, if: :key_is_serial?
  validates_format_of     :key, with: /\A.+\:.e-\d\/\d\/\d{1,2}\.0\Z/, if: :key_is_port?
  validates_format_of     :key, with: /\A(ex|qfx)\d+.*\Z/, if: :key_is_model?

  private

  def key_is_mac?
    return keytype == 'mac'
  end

  def key_is_serial?
    return keytype == 'serial'
  end

  def key_is_port?
    return keytype == 'port'
  end

  def key_is_model?
    return keytype == 'model'
  end
end
