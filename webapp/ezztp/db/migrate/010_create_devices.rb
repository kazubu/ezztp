class CreateDevices < ActiveRecord::Migration
  def self.up
    create_table :devices do |t|
      t.string :keytype
      t.string :key
      t.integer :configuration_template_id
      t.timestamps
    end
  end

  def self.down
    drop_table :devices
  end
end
