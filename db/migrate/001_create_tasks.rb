class CreateTasks < ActiveRecord::Migration
  def self.up
    create_table :tasks do |t|
      t.text :details
      t.boolean :reconciled
      t.integer :time_spent
      
      t.timestamps
    end
    
    add_index :tasks, :reconciled
    add_index :tasks, :created_at
  end
  
  def self.down
    drop_table :tasks
  end
end