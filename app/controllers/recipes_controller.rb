@@ing_database_size = Ingredient.count
GENE_LENGTH = 4 # initial length for sandwiches
MAX_GENES = 6 # max length for sandwiches
MAX_QUANTITY = 5 # Maximum quantity for an ingredient
ELITISM = true
CROSSOVER_RATE = 0.6 # 60% chance that two parents will reproduce.
MICRO_MUTATION_RATE = 0.3 # should be way lower
MACRO_MUTATION_RATE = 0.1 # should be way lower
TOURNAMENT_SIZE = 2
SELECTION_RATIO = 0.7 # chance fittest recipe selected in tournament


# Algorithm used to actually evolve populations.
class Algorithm

  # Evolve new population
  def self.evolve_population(pop)
    new_pop = Population.new(pop.size, false)

    # If we are using elitism, carry best recipe over straight away
    new_pop.save_sandwich(0, pop.get_best_sandwich) if ELITISM
    sandwiches_added = ELITISM ? 1 : 0 # account for added elite recipe

    # While we haven't filled up the new population
    while sandwiches_added < pop.size
      # Pick two sandwiches through tournament selection
      sandwich1 = tournament_selection(pop)
      sandwich2 = tournament_selection(pop)

      if rand <= CROSSOVER_RATE # If they are selected to breed, cross them over.
        crossed_over = crossover(sandwich1, sandwich2)
        co_sandwich1 = crossed_over[0]
        co_sandwich2 = crossed_over[1]
      else # The 'crossed over' sandwiches are the same
        co_sandwich1 = sandwich1
        co_sandwich2 = sandwich2
      end

      mutated_sandwich1 = mutate(co_sandwich1)
      mutated_sandwich2 = mutate(co_sandwich2)

      to_save = (mutated_sandwich1.get_fitness >= mutated_sandwich2.get_fitness) ? mutated_sandwich1 : mutated_sandwich2
      new_pop.save_sandwich(sandwiches_added, to_save)

      sandwiches_added += 1
    end

    new_pop
  end

  def self.tournament_selection(pop)
    # create a tournament population to select from
    tournament_pop = Population.new(TOURNAMENT_SIZE, false)

    # get two random sandwiches
    tournament_pop.save_sandwich(0, pop.get_sandwich(Random.rand(pop.size)))
    tournament_pop.save_sandwich(1, pop.get_sandwich(Random.rand(pop.size)))

    if rand < SELECTION_RATIO # choose fittest
      selected = tournament_pop.get_best_sandwich
    else
      selected = tournament_pop.get_worst_sandwich
    end

    selected
  end

  # TODO: Code logic for crossover
  def self.crossover(sandwich1, sandwich2)
    sandwich1_split = sandwich1.get_genes.in_groups(@@ing_database_size/5, false) #{|group| p group}
    sandwich2_split = sandwich2.get_genes.in_groups(@@ing_database_size/5, false) #{|group| p group}

    genome_pairs = sandwich1_split.zip sandwich2_split
    co_pairs = []

    # For every set of genome pairs, choose a random crossover point
    genome_pairs.each do |genome1, genome2|
      co_point = rand(genome1.size)

      co_genome1 = genome1.first(co_point) + genome2.last(genome2.size-co_point)
      co_genome2 = genome2.first(co_point) + genome1.last(genome1.size-co_point)

      pair_array = []
      pair_array.push(co_genome1) # make the genomes into a pair
      pair_array.push(co_genome2)
      co_pairs.push(pair_array) # push the pair into the list of existing one
    end

    co_genes1 = []; co_genes2 = []
    co_pairs.each do |genome1, genome2|
      co_genes1.push(genome1)
      co_genes2.push(genome2)
    end

    co_sandwich1 = Sandwich.new
    co_genes1.flatten!
    puts co_genes1.inspect
    co_sandwich1.build_sandwich(co_genes1)


    co_sandwich2 = Sandwich.new
    co_genes2.flatten!
    puts co_genes2.inspect
    co_sandwich2.build_sandwich(co_genes2)

    return co_sandwich1, co_sandwich2
  end

  def self.mutate(sandwich)

    # loop over all the genes in a sandwich
    (1...sandwich.size).each do |i|
      # attempt to macro mutate, then micro mutate.
      if rand <= MACRO_MUTATION_RATE
        if sandwich.get_gene(i) > 0 # then we want to mutate the ingredient away
          sandwich.set_gene(i, 0)
        elsif sandwich.no_of_ing < MAX_GENES# otherwise we want to mutate it in
          sandwich.set_gene(i, 1)
        end
      end

      gene = sandwich.get_gene(i)
      inc_or_dec = rand
      if rand <= MICRO_MUTATION_RATE && gene > 0 # can only micro mutate existing ingredients
        sandwich.set_gene(i, gene + 1) if inc_or_dec > 0.5 && gene < MAX_QUANTITY
        sandwich.set_gene(i, gene - 1) if inc_or_dec < 0.5 && gene > 1
      end
    end
    sandwich
  end
end

# Digital Representation of real life sandwich recipe
# Array of ints, each index associated with a different ingredient

class Sandwich

  def initialize
    @gene_length = GENE_LENGTH
    @fitness = 0
    @genes = Array.new(@@ing_database_size, 0)
  end

  def build_sandwich(gene_array)
    (0...gene_array.size).each do |i|
      @genes[i] = gene_array[i]
    end
  end

  def generate_sandwich
    @genes[0] = 2 # Must have two slices of bread!

    database_pointer = 0
    ingredients_added = 0
    # RANDOM GENERATION START
    while ingredients_added < GENE_LENGTH # while we don't have enough ingredients
      database_pointer = 0 if database_pointer == @@ing_database_size

      if rand <= 0.35 && ingredients_added < GENE_LENGTH && @genes[database_pointer] == 0
        @genes[database_pointer] = rand(4)+1 # gene initialized with random quantity, 1 -> 5
        ingredients_added += 1
      end
      database_pointer += 1
    end # RANDOM GENERATION END
    @fitness = get_fitness
  end

  def get_fitness
    if @fitness <= 0
      @fitness = FitnessCalc.goog_fitness_calc(self)
    end
    @fitness
  end

  #Getters and setters
  def get_genes
    @genes
  end

  def get_gene(index)
    @genes[index]
  end

  def set_gene(index, value)
    if index >= @@ing_database_size || index < 0
      raise 'Index out of bounds, make sure 0 <= index <= ING_DATABASE_SIZE'
    end
    @genes[index] = value
    @fitness = 0
  end

  def size
    @genes.length
  end

  def no_of_ing # number of ingredients being used (>1)
    no_of_ing = 0
    @genes.each do |i|
      no_of_ing += 1 if i > 0
    end
    no_of_ing
  end

  def ing_db_keys # returns array of ints representing ingredient ids
    ingredient_ids = []

    (1..@@ing_database_size).each do |i|
      # find id for ingredient if it is in sandwich
      ingredient_ids.push(i) if @genes[i-1] > 0 # offset because of database IDs
    end

    ingredient_ids
  end

  def get_query_string
    query_string = ''
    # Get all ingredients with the list of found IDs (faster to do one query)
    Ingredient.find(ing_db_keys).each do |ing|
      # Get their names and add them to query string
      query_string += ing.ing_name
      query_string += ', '
    end
    query_string.strip!
  end
end

# A population is a collection of sandwich recipes
# These sandwich's will be chosen to mutate and create new recipes for a new generation
class Population
  require('yummly') # for recipe and ingredient population
  @sandwiches = []

  def initialize(pop_size, generate_recipes=false, ings=nil)
    @sandwiches = Array.new(pop_size, Sandwich.new)

    if generate_recipes && ings == nil # Entirely random recipes
      (0...size).each do |i|
        new_sandwich = Sandwich.new
        new_sandwich.generate_sandwich
        save_sandwich(i, new_sandwich)
      end
    elsif not(ings == nil) # Recipes containing mentioned ingredients
      result = Yummly.search(ings)
      yummly_recipes = result.collect{ |recipe| recipe }

      # Update ing DB before sandwiches made to ensure gene length is uniform
      update_ing_db(yummly_recipes)
      @@ing_database_size = Ingredient.count

      (0...size).each do |i|
        save_sandwich(i, build_sandwich(yummly_recipes[i].ingredients))
      end
    end
  end

  def update_ing_db(recipes)
    recipes.each do |recipe|
      recipe.ingredients.each do |ing|
        # populate database to update sizes
        ing_to_check = Ingredient.find_by(ing_name: ing)
        if ing_to_check == nil
          Ingredient.create!(ing_name: ing.downcase)
        end
      end
    end
  end

  # If yummly search was done, take ingredients and build a sandwich
  def build_sandwich(ingredients)
    sandwich = Sandwich.new
    sandwich.set_gene(0, 2) # make sure there is bread!
    ingredients.each do |ing|
      gene_index = Ingredient.find_by(ing_name: ing).id - 1 #offset for db starting at 1
      sandwich.set_gene(gene_index, 1) # add one of the chosen ingredient
    end
    sandwich.get_fitness
    sandwich
  end

  # TODO: Maybe need to fix this
  def get_best_sandwich
    fittest = @sandwiches[0]
    @sandwiches.each do |sandwich|
      fittest = sandwich if sandwich.get_fitness >= fittest.get_fitness
    end
    fittest
  end

  # used for tournament selection
  def get_worst_sandwich
    worst = @sandwiches[0]
    @sandwiches.each do |sandwich|
      worst = sandwich if sandwich.get_fitness <= worst.get_fitness
    end
    worst
  end

  # Getters and setters
  def get_sandwich(index)
    sandwich = @sandwiches[index]
    sandwich
  end

  def save_sandwich(index, sandwich)
    @sandwiches[index] = sandwich
  end

  def size
    @sandwiches.length
  end
end

# This will be a 'static' class that will contain methods needed to workout the fitness
# of a recipe, basically exists to help keep code clean.
class FitnessCalc
  require ('google-search')
  @google_search = Google::Search::Web.new

  def self.goog_fitness_calc(sandwich)
    search = sandwich.get_query_string
    if sandwich.get_query_string.include?('bread')

      # Check to see if we've already searched this
      db_check = SearchCombination.find_by(query_name: search)
      if db_check == nil # If it's not been searched before
        @google_search.query = search
        fitness = @google_search.response.estimated_count
        SearchCombination.create!(query_name: search, fitness: fitness)
      else # if it has
        fitness = db_check.fitness
      end
    else
      fitness = 1
    end
    fitness
  end

  def self.yumm_fitness_calc(sandwich)

  end
end

class RecipesController < ApplicationController
  before_action :set_recipe, only: [:show, :edit, :update, :destroy]

  # GET /recipes
  # GET /recipes.json
  def index
    @recipes = Recipe.all
  end

  def home
    @random_recipe = Recipe.order("RANDOM()").first
    @ing_quant_pairs = get_recipe_ingredients(@random_recipe)

    # Get all the ingredient ids linked to the recipe id and their quantities.
    # Recipe2Ingredient.where(recipe_id: @random_recipe.id).each do |link_id|
    #
    #   ing = Ingredient.find(link_id.ing_id).ing_name
    #   quant = link_id.quantity
    #
    #   @ing_quant_pairs.push([ing, quant])
    # end
  end

  # GET /recipes/1
  # GET /recipes/1.json
  def show
    @ing_quant_pairs = get_recipe_ingredients(@recipe)
  end

  # GET /recipes/new
  def new
    @recipe = Recipe.new
  end

  # GET /recipes/1/edit
  def edit
  end

  # POST /recipes
  # POST /recipes.json
  def create
    # RECIPE CREATING
    if recipe_params.fetch('recipe_name').blank?
      my_pop = Population.new(10, true)
    else # If an ingredient was, given have initial pop be from Yummly
      my_pop = Population.new(10, false, recipe_params.fetch('recipe_name'))
    end

    (0...10).each do |i|
       my_pop = Algorithm.evolve_population(my_pop)
    end
    best_sandwich = my_pop.get_best_sandwich

    # RECIPE SAVING
    @recipe = Recipe.new({ "recipe_name" => name_maker(best_sandwich) })

    respond_to do |format|
      if @recipe.save
        save_ing_links(@recipe.id, best_sandwich.get_genes)
        format.html { redirect_to @recipe, notice: 'Recipe was successfully created.' }
        format.json { render :show, status: :created, location: @recipe }
      else
        format.html { render :new }
        format.json { render json: @recipe.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /recipes/1
  # PATCH/PUT /recipes/1.json
  def update
    respond_to do |format|
      if @recipe.update(recipe_params)
        format.html { redirect_to @recipe, notice: 'Recipe was successfully updated.' }
        format.json { render :show, status: :ok, location: @recipe }
      else
        format.html { render :edit }
        format.json { render json: @recipe.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /recipes/1
  # DELETE /recipes/1.json
  def destroy
    @recipe.destroy
    respond_to do |format|
      format.html { redirect_to recipes_url, notice: 'Recipe was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_recipe
      @recipe = Recipe.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def recipe_params
      params.require(:recipe).permit(:recipe_name)
    end

    # get the ingredient/quantity pairs for a recipe
    def get_recipe_ingredients(recipe)
      ing_quant_pairs = []
      Recipe2Ingredient.where(recipe_id: recipe.id).each do |link_id|

        ing = Ingredient.find(link_id.ing_id).ing_name
        quant = link_id.quantity

        ing_quant_pairs.push([ing, quant])
      end
      ing_quant_pairs
    end

    def name_maker(sandwich)
      ing_ids = sandwich.ing_db_keys

      name = Ingredient.find(ing_ids[rand(ing_ids.size)]).ing_name + ', '
      name += Ingredient.find(ing_ids[rand(ing_ids.size)]).ing_name + ' and '
      name += Ingredient.find(ing_ids[rand(ing_ids.size)]).ing_name + ' '
      name += 'sandwich'
      name
    end

    def save_ing_links(recipe_id, sandwich_genes)
      rec_id = recipe_id
      (0...sandwich_genes.size).each do |i|
        ingredient_id = i+1
        if sandwich_genes[i] > 0
          Recipe2Ingredient.create!(ing_id: ingredient_id, recipe_id: rec_id, quantity: sandwich_genes[i])
        end
      end
    end
end
