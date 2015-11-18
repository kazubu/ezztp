class AddFieldsToManagementSwitch2 < ActiveRecord::Migration
  def self.up
    change_table :management_switches do |t|
    t.string :base_ip_address
    t.string :number_of_vc_member
    end
  end

  def self.down
    change_table :management__switches do |t|
    t.remove :base_ip_address
    t.remove :number_of_vc_member
    end
  end
end
