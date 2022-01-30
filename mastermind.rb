# frozen_string_literal: true

# This is a module that handles game logic of Mastermind.
module Rules
  COLOURS = %w[pink red green blue purple yellow].freeze
  GUESS_SPACE = [' ', ' ', ' ', ' '].freeze
  HINT_SPACE = [' ', ' ', ' ', ' '].freeze
  GAMEBOARD = [GUESS_SPACE, HINT_SPACE].freeze

  def make_guess(guess, gameboard)

    p guess == player2.secret_code
    p @turn += 1
    Display.add_guess(guess, gameboard)
  end
end

# This class handles the display.
class Display
  include Rules
  attr_reader :gameboard

  def initialize
    @gameboard = [[GUESS_SPACE], [HINT_SPACE]]
  end

  def self.introduce_rules
    puts 'These are the possible colours in the game:'
    print COLOURS
    puts "\nWhen asked type the colours out in a particular order separated by a space."
    print GAMEBOARD
    puts "\nThis is how the gameboard looks like - your guesses will be on the left and your hints will be on the right."
    puts 'White on the right means there is such colour in code but not in its place.'
    puts 'Black on the right means a colour is in its place.'
    puts 'Good luck and have fun!'
  end

  def self.make_guess
    puts 'What is your guess?'
  end

  def self.add_guess(guess, gameboard)
    gameboard[0][0] = guess if gameboard[0][0] == GUESS_SPACE
  end

  def self.show_gameboard(gameboard)
    print gameboard
  end
end

# This class handles the Mastermind game.
class Mastermind
  include Rules
  attr_reader :player1_name, :player2_name, :game_name, :player1, :player2

  @game_count = 0

  def initialize
    @gameboard = Display.new.gameboard
    @game_name = "Game #{self.class.count}"
    @turn = 0
  end

  def add_players(player1, player2)
    return "#{player1_name} and #{player2_name} are already playing!" if player1_name && player2_name

    @player1 = player1
    @player2 = player2
    @player1_name = player1.name
    @player2_name = player2.name
    "Added #{player1_name} and #{player2_name} to #{game_name}."
  end

  def play
    Display.introduce_rules
    Display.make_guess
    make_guess(gets.chomp.to_s.downcase.split(' '), @gameboard)
    Display.show_gameboard(@gameboard)
  end

  def self.count
    @game_count += 1
  end
end

# This class handles player info and creation.
class Player
  attr_reader :name, :points, :ishuman

  def initialize(name)
    @name = name.to_s
    @role = nil
    @points = nil
  end
end

# This is a class that handles Human players.
class Human < Player
  attr_reader :name, :points, :ishuman

  def initialize(name)
    super(name)
    @ishuman = true
  end
end

# This is a class that handles Computer players.
class Computer < Player
  include Rules
  attr_reader :name, :points, :ishuman, :secret_code

  def initialize(name)
    super(name)
    @ishuman = false
  end

  # rubocop:disable Layout/LineLength, Metrics/ParameterLists
  def create_code(colour1 = COLOURS.sample, colour2 = COLOURS.sample, colour3 = COLOURS.sample, colour4 = COLOURS.sample)
    @secret_code = [colour1, colour2, colour3, colour4]
  end
  # rubocop:enable Layout/LineLength, Metrics/ParameterLists
end

space_oddysey = Mastermind.new
brave = Human.new('Dave')
hal = Computer.new('Hal')
p brave
p hal
p hal.create_code
space_oddysey.add_players(brave, hal)
space_oddysey.play
