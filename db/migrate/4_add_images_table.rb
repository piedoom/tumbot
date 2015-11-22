class AddImagesTable < ActiveRecord::Migration
	def change
		create_table :images do |t|
			t.string :url, :default => "https://placehold.it/350x150"
		end
	end
end
