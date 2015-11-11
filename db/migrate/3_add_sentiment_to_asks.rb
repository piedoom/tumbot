class AddSentimentToAsks < ActiveRecord::Migration
	def change
		add_column :asks, :sentiment, :decimal, :default => 0
	end
end
