class AddFieldsToManagementSwitch < ActiveRecord::Migration
  def self.up
    change_table :management_switches do |t|
    t.string :name
    t.string :subscriber_id
    end
  end

  def self.down
    change_table :management__switches do |t|
    t.remove :name
    t.remove :subscriber_id
    end
  end
end
