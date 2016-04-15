class CreateRecipe2Ingredients < ActiveRecord::Migration
  def change
    create_table :recipe2_ingredients do |t|
      t.integer :ing_id
      t.integer :recipe_id
      t.integer :quantity

      t.timestamps
    end
  end
end
