class AddFieldsToDevices < ActiveRecord::Migration
  def self.up
    change_table :devices do |t|
      t.integer :image_id
    end
  end

  def self.down
    change_table :devices do |t|
      t.remove :image_id
    end
  end
end

