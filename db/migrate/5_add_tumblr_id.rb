class AddTumblrId < ActiveRecord::Migration
	def change
		add_column :asks, :tumblr_id, :string, :default => 0
	end
end
