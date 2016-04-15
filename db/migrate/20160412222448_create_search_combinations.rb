class CreateSearchCombinations < ActiveRecord::Migration
  def change
    create_table :search_combinations do |t|
      t.string :query_name
      t.integer :fitness

      t.timestamps
    end
  end
end
