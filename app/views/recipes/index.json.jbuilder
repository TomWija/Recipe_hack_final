json.array!(@recipes) do |recipe|
  json.extract! recipe, :id, :recipe_name
  json.url recipe_url(recipe, format: :json)
end
