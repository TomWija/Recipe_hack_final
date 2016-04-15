ING_DATABASE_SIZE = Ingredient.count
GENE_LENGTH = 4 # initial length for sandwiches
MAX_GENES = 6 # max length for sandwiches
MAX_QUANTITY = 5 # Maximum quantity for an ingredient
ELITISM = true
CROSSOVER_RATE = 0.6 # 60% chance that two parents will reproduce.
MICRO_MUTATION_RATE = 0.2 # should be way lower
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

      # TODO: Uncomment after finishing crossover.
      if rand <= CROSSOVER_RATE # If they are selected to breed, cross them over.
        co_sandwich1 = sandwich1 #crossover(sandwich1, sandwich2)
        co_sandwich2 = sandwich2 #crossover(sandwich1, sandwich2)
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
    sandwich1_split = sandwich1.in_groups(6, false)
    sandwich2_split = sandwich2.in_groups(6, false)


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

      # TODO: Weird array issue, not hugely important for testing.
      # gene = sandwich.get_gene(i)
      # inc_or_dec = rand
      # if rand <= MICRO_MUTATION_RATE && gene > 0 # can only micro mutate existing ingredients
      #   sandwich.set_gene(i, gene + 1) if inc_or_dec > 0.5 && gene < MAX_QUANTITY
      #   sandwich.set_gene(i, gene - 1) if inc_or_dec < 0.5 && gene > 1
      # end
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
    @genes = Array.new(ING_DATABASE_SIZE, 0)
  end

  def generate_sandwich
    @genes[0] = 2 # Must have two slices of bread!

    database_pointer = 0
    ingredients_added = 0
    # RANDOM GENERATION START
    while ingredients_added < GENE_LENGTH # while we don't have enough ingredients
      database_pointer = 0 if database_pointer == ING_DATABASE_SIZE

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
    if index >= ING_DATABASE_SIZE || index < 0
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

    (1..ING_DATABASE_SIZE).each do |i|
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
  @sandwiches = []

  def initialize(pop_size, generate_recipes)
    @sandwiches = Array.new(pop_size, Sandwich.new)

    if generate_recipes
      (0...size).each do |i|
        new_sandwich = Sandwich.new
        new_sandwich.generate_sandwich
        save_sandwich(i, new_sandwich)
      end
    end
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
    # require('benchmark')
    #
    # @times = Benchmark.measure {
    # my_pop = Population.new(10, true)
    # (0...15).each do |i|
    #   my_pop = Algorithm.evolve_population(my_pop)
    # end
    # best_sandwich = my_pop.get_best_sandwich
    # @sandwich_string = best_sandwich.get_query_string
    # }

    @recipes = Recipe.all
  end

  def home
    @random_recipe = Recipe.order("RANDOM()").first
    @ing_quant_pairs = []

    # Get all the ingredient ids linked to the recipe id and their quantities.
    Recipe2Ingredient.where(recipe_id: @random_recipe.id).each do |link_id|
      puts ' LINK ID: ' + link_id.to_s
      puts ' LINK ID ING ID: ' + link_id.ing_id.to_s

      ing = Ingredient.find(link_id.ing_id).ing_name
      quant = link_id.quantity

      puts 'Ingredient: ' + ing.to_s + ' ID: ' + link_id.ing_id.to_s

      @ing_quant_pairs.push([ing, quant])
    end
  end

  # GET /recipes/1
  # GET /recipes/1.json
  def show
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
    @recipe = Recipe.new(recipe_params)

    respond_to do |format|
      if @recipe.save
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
end
