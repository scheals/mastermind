# frozen_string_literal: true

# This is a module that handles game logic of Mastermind.
module Rules
  COLOURS = %w[pink red green blue purple yellow].freeze
  GUESS_SPACE = [' ', ' ', ' ', ' '].freeze
  HINT_SPACE = [' ', ' ', ' ', ' '].freeze
  GAMEBOARD = [[GUESS_SPACE], [HINT_SPACE]].freeze

  def make_guess(guess, turn)
    return play unless legal?(guess)

    @turn += 1
    win?(guess) ? codebreaker_wins : codemaker_wins(turn_limit?(turn))

    display.add_guess(guess, turn)
    return display.add_hint([' ', ' ', ' ', ' '], turn) unless check_any?(guess)

    create_hint(guess, turn)
    display.show_gameboard
    play
  end

  def check_any?(guess)
    return false if secret_code.intersection(guess).empty?

    true
  end

  def create_hint(guess, turn)
    hint = []
    check_colours(check_matches(guess, hint), hint)

    display.add_hint(hint, turn)
  end

  def check_colours(guess_without_perfect_matches, hint)
    hint.push(guess_without_perfect_matches.intersection(secret_code).map { 'exists' })
  end

  def check_matches(guess, hint)
    perfect_matches = guess.filter.with_index { |colour, i| colour == secret_code[i] }
    hint.push(perfect_matches.map { 'perfect' })
    guess - perfect_matches
  end

  def legal?(guess)
    if guess.length != 4
      puts 'There are four spaces to fill.'
      return false
    end
    unless guess.all? { |colour| COLOURS.include?(colour) }
      puts 'At least one of the colours is not a possible one in the game.'
      return false
    end
    true
  end

  def win?(guess)
    return true if guess == secret_code

    false
  end

  def turn_limit?(turn)
    p turn
    return true if turn == 10

    false
  end

  def codebreaker_wins
    display.codebreaker_win
    declare_winner
  end

  def codemaker_wins(turn_limit_reached)
    if turn_limit_reached
      display.codemaker_win
      declare_winner
    end
  end
end

# This class handles the display.
class Display
  include Rules
  attr_reader :gameboard

  def initialize
    @gameboard = [[GUESS_SPACE], [HINT_SPACE]]
  end

  def introduce_rules
    puts 'These are the possible colours in the game:'
    print COLOURS
    puts "\nWhen asked type the colours out in a particular order separated by a space.\n\n"
    print GAMEBOARD
    puts "\nThis is how the gameboard looks like - your guesses will be on the left and your hints will be on the right.\n"
    puts "'Exists' on the right means there is such colour in code but not in its place."
    puts "'Perfect' on the right means a colour is in its place."
    puts 'You\'ve got 10 turns to guess correctly.'
    puts "\nGood luck and have fun!"
  end

  def ask_guess
    puts "\nWhat is your guess?"
  end

  def add_guess(guess, turn)
    return gameboard[0] = [guess] if turn == 1

    gameboard[0].push(guess)
  end

  def add_hint(hint, turn)
    return gameboard[1] = [hint] if turn == 1

    gameboard[1].push(hint)
  end

  def show_gameboard
    gameboard[0].length.times do |i|
      puts "#{gameboard[0][i]} #{gameboard[1][i]}"
    end
  end

  def in_progress
    puts 'Game is already in progress.'
  end

  def game_end
    puts 'Game has already ended.'
  end

  def codebreaker_win
    puts "Congratulations, you've guessed correctly!"
  end

  def codemaker_win
    puts "Congratulations, your code was not broken!"
  end
end

# This class handles the Mastermind game.
class Mastermind
  include Rules
  attr_reader :player1_name, :player2_name, :game_name, :player1, :player2, :secret_code,
              :display, :gameboard

  @game_count = 0

  def initialize
    @display = Display.new
    @gameboard = @display.gameboard
    @game_name = "Game #{self.class.count}"
    @turn = 1
    @in_progress = true
  end

  def add_players(player1, player2)
    return "#{player1_name} and #{player2_name} are already playing!" if player1_name && player2_name

    @player1 = player1
    @player2 = player2
    @player1_name = player1.name
    @player2_name = player2.name
    "Added #{player1_name} and #{player2_name} to #{game_name}."
  end

  def start
    return display.in_progress unless @in_progress

    display.introduce_rules
    @secret_code = player2.create_code
    p secret_code
    play
  end

  def self.count
    @game_count += 1
  end

  private

  def play
    return display.game_end unless @in_progress

    display.ask_guess
    make_guess(gets.chomp.to_s.downcase.split(' '), @turn)
  end

  def declare_winner
    @in_progress = false
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
  attr_reader :name, :points, :ishuman

  def initialize(name)
    super(name)
    @ishuman = false
  end

  def create_code(*code)
    code << COLOURS.sample while code.length < 5
    @secret_code = code[0..3]
  end
end
space_oddysey = Mastermind.new
brave = Human.new('Dave')
hal = Computer.new('Hal')
space_oddysey.add_players(brave, hal)
space_oddysey.start