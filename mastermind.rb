# frozen_string_literal: true

# This is a module that handles the rules.
module Rules
  COLOURS = %w[pink red green blue purple yellow].freeze
  GUESS_SPACE = [' ', ' ', ' ', ' '].freeze
  HINT_SPACE = [' ', ' ', ' ', ' '].freeze
  GAMEBOARD = [[GUESS_SPACE], [HINT_SPACE]].freeze

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
end

# This is Swaszek's algorithm for code breaking.
module Swaszek
  def read_results(turn)
    perfects = board.gameboard[1][turn - 2][0].length if turn > 1
    exists = board.gameboard[1][turn - 2][1].length if turn > 1
    calculate_possibilities(perfects, exists, turn)
  end

  def read_guess(turn)
    create_all_possibilities if @possibilities.nil?
    board.gameboard[0][turn - 2] if turn > 1
  end

  def create_all_possibilities
    @possibilities = []
    Rules::COLOURS.repeated_permutation(4) { |possibility| @possibilities.push(possibility) }
    @possibilities
  end

  def calculate_possibilities(perfects, exists, turn)
    guess = read_guess(turn)
    guesses = guess.tally
    if (perfects + exists).zero?
      zero_hits(guess)
    elsif exists == 4
      all_exists(guess, guesses)
    elsif (perfects + exists) == 4
      four_hits(guess, guesses, perfects)
    else
      various_hits(guess, guesses, perfects, exists)
    end
    @possibilities.reject! { |possibility| possibility == guess }
  end

  def zero_hits(guess)
    4.times do |i|
      next if guess[i] == guess[i - 1]

      @possibilities.reject! { |possibility| possibility.include?(guess[i]) }
    end
    @possibilities.reject! { |possibility| possibility == guess }
  end

  def all_exists(guess, guesses)
    @possibilities.select! { |possibility| guesses == possibility.tally }
    @possibilities.reject! do |possibility|
      flag = false
      possibility.each_index do |index|
        break flag = true if possibility[index] == guess[index]
      end
      next false unless flag == true

      next true
    end
    @possibilities.reject! { |possibility| possibility == guess }
  end

  def four_hits(guess, guesses, perfects)
    @possibilities.select! { |possibility| guesses == possibility.tally }
    @possibilities.reject! do |possibility|
      counter = 0
      possibility.each_index do |index|
        counter += 1 if possibility[index] == guess[index]
      end
      next false if counter == perfects

      next true
    end
    @possibilities.reject! { |possibility| possibility == guess }
  end

  def various_hits(guess, guesses, perfects, exists)
    understand_hint(guesses, perfects, exists)
    understand_perfects(guess, perfects)
    @possibilities.reject! { |possibility| guesses == possibility.tally }
  end

  def understand_perfects(guess, perfects)
    @possibilities.reject! do |possibility|
      counter = 0
      possibility.each_index do |index|
        counter += 1 if possibility[index] == guess[index]
      end
      next false if counter == perfects

      next true
    end
  end

  def understand_hint(guesses, perfects, exists)
    @possibilities.reject! do |possibility|
      count = {}
      count.default = 0
      possibility.each do |colour|
        count[colour] = possibility.count(colour) if guesses.keys.include?(colour)
      end
      next true if (perfects + exists) > count.values.sum

      next false
    end
  end
end

# This class handles the display.
class Display
  include Rules

  attr_reader :board

  def initialize
    @type = "I'm a console display!"
    @game = nil
    @board = nil
  end

  def attach_game(game)
    @game = game
  end

  def attach_board(board)
    @board = board
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

  def ask_code
    puts 'What should the code be? Enter up to 4 pieces, any undeclared piece is going to be randomized.'
  end

  def in_progress
    puts 'Game is already in progress.'
  end

  def game_end
    puts 'Game has already ended.'
  end

  def win_message(winner)
    puts "Congratulations #{winner}, you've won!"
  end

  def codebreaker_win(turn, codebreaker)
    show_gameboard(turn - 1)
    puts "Congratulations #{codebreaker.name}, you've guessed correctly!"
  end

  def codemaker_win(turn, codemaker)
    show_gameboard(turn - 1)
    puts "Congratulations #{codemaker.name}, your code was not broken!"
  end

  def show_gameboard(turn)
    puts "Turn #{turn}"
    puts 'This is the current state of the gameboard:'
    board.gameboard[0].length.times do |i|
      puts "#{board.gameboard[0][i]} #{board.gameboard[1][i]}"
    end
  end
end

# This class handles the gameboard logic.
class Board
  include Rules
  attr_reader :gameboard, :turn

  def initialize
    @gameboard = [[GUESS_SPACE], [HINT_SPACE]]
    @game = nil
  end

  def attach_game(game)
    @game = game
  end

  def attach_display(display)
    @display = display
    display.attach_board(self)
  end

  def begin_game
    Player.add_to_board(@game.player1, @game.player2, self)
    @turn = 1
    @secret_code = @game.codemaker.create_code
    @game.codebreaker.game_loop
  end

  def make_guess(guess)
    return @game.codebreaker.play unless legal?(guess)

    add_guess(guess)
    if check_any?(guess)
      create_hint(guess)
    else
      add_hint([[], []])
    end
    @turn += 1
    win?(guess) ? codebreaker_wins : codemaker_wins(turn_limit?)
  end

  def add_guess(guess)
    return @gameboard[0] = [guess] if @turn == 1

    @gameboard[0].push(guess)
  end

  def add_hint(hint)
    return @gameboard[1] = [hint] if @turn == 1

    @gameboard[1].push(hint)
  end

  def check_any?(guess)
    return false if @secret_code.intersection(guess).empty?

    true
  end

  def create_hint(guess)
    hint = [[], []]
    check_matches(guess, hint)
    add_hint(hint)
  end

  def check_colours(colours, code, hint)
    colours.each do |colour, count|
      while (code[colour] >= count || count >= code[colour]) && code[colour].positive? && count.positive?
        hint[1].push('exists')
        code[colour] -= 1
        count -= 1
      end
    end
  end

  def check_matches(guess, hint)
    perfect_matches = guess.filter.with_index { |colour, i| colour == @secret_code[i] }
    hint[0] = perfect_matches.map { 'perfect' }
    tally_helper(guess, perfect_matches, hint)
  end

  def tally_helper(guess, matches, hint)
    tallied_matches = matches.tally
    tallied_guess = guess.tally
    tallied_code = @secret_code.tally
    tallied_matches.default = 0
    tallied_guess.default = 0
    tallied_code.default = 0
    check_colours(drop_guess_matches(tallied_guess, tallied_matches), drop_code_matches(tallied_code, tallied_matches), hint)
  end

  def drop_code_matches(code, matches)
    code.each { |colour, count| code[colour] = count - matches[colour] }
  end

  def drop_guess_matches(guess, matches)
    guess.each { |colour, count| guess[colour] = count - matches[colour] }
  end

  def win?(guess)
    return true if guess == @secret_code

    false
  end

  def turn_limit?
    return true if @turn > 10

    false
  end

  def codebreaker_wins
    @display.codebreaker_win(@turn, @game.codebreaker)
    @game.stats[:codebreaker] += 1
    @game.declare_winner
  end

  def codemaker_wins(turn_limit_reached)
    return unless turn_limit_reached

    @display.codemaker_win(@turn, @game.codemaker)
    @game.stats[:codemaker] += 1
    @game.declare_winner
  end
end

# This class handles the Mastermind game.
class Mastermind
  attr_reader :player1_name, :player2_name, :game_name, :player1, :player2,
              :display, :board, :codemaker, :codebreaker, :in_progress
  attr_accessor :stats

  @game_count = 0

  def initialize
    @game_name = "Game #{self.class.count}"
    @stats = { codemaker: 0, codebreaker: 0 }
  end

  def add_players(player1, player2)
    return "#{player1_name} and #{player2_name} are already playing!" if player1_name && player2_name

    @player1 = player1
    @player2 = player2
    Player.add_to_game(player1, player2, self)
    @player1_name = player1.name
    @player2_name = player2.name
    ask_roles
    "Added #{player1_name} and #{player2_name} to #{game_name}."
  end

  def attach_display(display)
    @display = display
    display.attach_game(self)
    "Added #{display} to #{game_name}"
  end

  def attach_board(board)
    @board = board
    board.attach_game(self)
    "Added #{board} to #{game_name}"
  end

  def start
    return unless players_ready? && display_ready? && board_ready?

    @in_progress = true if @in_progress.nil?
    return display.game_end unless @in_progress

    board.attach_display(display)
    display.introduce_rules
    board.begin_game
  end

  def self.count
    @game_count += 1
  end

  # private

  def declare_winner
    @in_progress = false
  end

  def ask_roles
    puts "Who should be the codemaker? Type 1 for #{player1_name} or type 2 for #{player2_name}."
    choice = gets.chomp.to_s
    if %w[1 2].include?(choice)
      choice == '1' ? Player.assign_roles(player1, player2) : Player.assign_roles(player2, player1)
      assign_roles
    else
      puts 'You have to input 1 or 2. Try again.'
      ask_roles
    end
  end

  def assign_roles
    @codemaker = player1.role == 'codemaker' ? player1 : player2
    @codebreaker = player1.role == 'codebreaker' ? player1 : player2
  end

  def players_ready?
    return true if player1 && player2

    puts 'This game is not yet ready to start. Make sure your players are present.'
    false
  end

  def display_ready?
    return true if display

    puts 'Seems like you forgot to attach your display.'
    false
  end

  def board_ready?
    return true if board

    puts 'Seems like you forgot to set up your gameboard.'
    false
  end
end

# This class handles player info and creation.
class Player
  include Rules
  attr_reader :name, :points, :ishuman
  attr_accessor :role, :game, :board

  def initialize(name)
    @name = name.to_s
    @role = nil
    @points = nil
    @game = nil
    @board = nil
  end

  def self.add_to_game(player1, player2, game)
    player1.game = game
    player2.game = game
  end

  def self.assign_roles(player1, player2)
    player1.role = 'codemaker'
    player2.role = 'codebreaker'
    puts "Added #{player1.name} as #{player1.role} and #{player2.name} as #{player2.role}."
  end

  def self.add_to_board(player1, player2, board)
    player1.board = board
    player2.board = board
  end
end

# This is a class that handles Human players.
class Human < Player
  attr_reader :name, :points, :ishuman

  def initialize(name)
    super(name)
    @ishuman = true
  end

  def create_code
    game.display.ask_code
    new_code = generate_code(gets.chomp.to_s.downcase)
    return create_code unless legal?(new_code)

    new_code
  end

  def generate_code(code)
    new_code = code.split(' ')
    new_code << COLOURS.sample while new_code.length < 5
    @secret_code = new_code[0..3]
  end

  def game_loop
    until board.turn_limit? || !game.in_progress
      game.display.show_gameboard(board.turn)
      play
    end
  end

  def play
    game.display.ask_guess
    board.make_guess(gets.chomp.to_s.downcase.split(' '))
  end
end

# This is a class that handles Computer players.
class Computer < Player
  include Swaszek
  attr_reader :name, :points, :ishuman, :possibilities

  def initialize(name)
    super(name)
    @ishuman = false
  end

  def create_code(*code)
    code << COLOURS.sample while code.length < 5
    @secret_code = code[0..3]
  end

  def game_loop
    until board.turn_limit? || !game.in_progress

      game.display.show_gameboard(board.turn)
      play
    end
  end

  def play
    return board.make_guess(create_code) if board.turn == 1

    read_results(board.turn)
    possibility = possibilities.sample
    board.make_guess(possibility)
  end
end
space_oddysey = Mastermind.new
cosmos = Display.new
spaceship = Board.new
brave = Human.new('Dave')
hal = Computer.new('HAL')
space_oddysey.add_players(brave, hal)
space_oddysey.attach_display(cosmos)
space_oddysey.attach_board(spaceship)
space_oddysey.start
p space_oddysey.stats
