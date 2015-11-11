class CreateAsksTable < ActiveRecord::Migration
	def change
		create_table :asks do |t|
			t.text :text
			t.integer :user_id
		end
	end
end
