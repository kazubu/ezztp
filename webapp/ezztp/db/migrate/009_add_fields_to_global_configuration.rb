class AddFieldsToGlobalConfiguration < ActiveRecord::Migration
  def self.up
    change_table :global_configurations do |t|
      t.string :name
    t.string :value
    end
  end

  def self.down
    change_table :global_configurations do |t|
      t.remove :name
    t.remove :value
    end
  end
end
