class CreateManagementSwitches < ActiveRecord::Migration
  def self.up
    create_table :management_switches do |t|
      
      t.timestamps
    end
  end

  def self.down
    drop_table :management_switches
  end
end
