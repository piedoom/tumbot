class AddTimestamps < ActiveRecord::Migration
	def change
		add_column :asks, :created_at, :datetime
	end
end
