class CreateGlobalConfigurations < ActiveRecord::Migration
  def self.up
    create_table :global_configurations do |t|
      
      t.timestamps
    end
  end

  def self.down
    drop_table :global_configurations
  end
end
