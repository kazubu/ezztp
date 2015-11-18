class CreateConfigurationTemplates < ActiveRecord::Migration
  def self.up
    create_table :configuration_templates do |t|
      
      t.timestamps
    end
  end

  def self.down
    drop_table :configuration_templates
  end
end
