class AddActivityScoreToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :activity_score, :integer, :default => 0
  end

  def self.down
    remove_column :users, :activity_score
  end
end
