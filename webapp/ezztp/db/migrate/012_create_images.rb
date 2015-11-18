class CreateImages < ActiveRecord::Migration
  def self.up
    create_table :images do |t|
      t.string :model
      t.string :version
      t.string :file_name
      t.timestamps
    end
  end

  def self.down
    drop_table :images
  end
end
