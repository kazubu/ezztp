class AddFieldsToConfigurationTemplate < ActiveRecord::Migration
  def self.up
    change_table :configuration_templates do |t|
      t.string :name
    t.text :template, :limit => 4294967295
    end
  end

  def self.down
    change_table :configuration_templates do |t|
      t.remove :name
    t.remove :template
    end
  end
end
