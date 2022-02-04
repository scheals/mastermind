# frozen_string_literal: true

# This is a module that handles game logic of Mastermind.
module Rules
  COLOURS = %w[pink red green blue purple yellow].freeze
  GUESS_SPACE = [' ', ' ', ' ', ' '].freeze
  HINT_SPACE = [' ', ' ', ' ', ' '].freeze
  GAMEBOARD = [[GUESS_SPACE], [HINT_SPACE]].freeze

  private

  def make_guess(guess, turn)
    return play unless legal?(guess)

    @turn += 1
    display.add_guess(guess, turn)
    if check_any?(guess)
      create_hint(guess, turn)
    else
      display.add_hint([' ', ' ', ' ', ' '], turn)
    end
    win?(guess) ? codebreaker_wins : codemaker_wins(turn_limit?)
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

  def check_any?(guess)
    return false if secret_code.intersection(guess).empty?

    true
  end

  def create_hint(guess, turn)
    hint = []
    check_matches(guess, hint)
    display.add_hint(hint, turn)
  end

  def check_colours(colours, code, hint)
    colours.each do |colour, count|
      while (code[colour] >= count || count >= code[colour]) && code[colour].positive? && count.positive?
        hint.push('exists')
        code[colour] -= 1
        count -= 1
      end
    end
  end

  def check_matches(guess, hint)
    perfect_matches = guess.filter.with_index { |colour, i| colour == secret_code[i] }
    hint.push(perfect_matches.map { 'perfect' })
    tally_helper(guess, perfect_matches, hint)
  end

  def tally_helper(guess, matches, hint)
    tallied_matches = matches.tally
    tallied_guess = guess.tally
    tallied_code = secret_code.tally
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
    return true if guess == secret_code

    false
  end

  def turn_limit?
    return true if @turn > 10

    false
  end

  def codebreaker_wins
    display.codebreaker_win(@turn, codebreaker)
    declare_winner
  end

  def codemaker_wins(turn_limit_reached)
    return unless turn_limit_reached

    display.codemaker_win(@turn, codemaker)
    declare_winner
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

  def ask_code
    puts 'What should the code be? Enter up to 4 pieces, any undeclared piece is going to be randomized.'
  end

  def add_guess(guess, turn)
    return gameboard[0] = [guess] if turn == 1

    gameboard[0].push(guess)
  end

  def add_hint(hint, turn)
    return gameboard[1] = [hint] if turn == 1

    gameboard[1].push(hint)
  end

  def show_gameboard(turn)
    puts "Turn #{turn}"
    puts 'This is the current state of the gameboard:'
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

  def codebreaker_win(turn, codebreaker)
    show_gameboard(turn - 1)
    puts "Congratulations #{codebreaker.name}, you've guessed correctly!"
  end

  def codemaker_win(turn, codemaker)
    show_gameboard(turn - 1)
    puts "Congratulations #{codemaker.name}, your code was not broken!"
  end
end

# This class handles the Mastermind game.
class Mastermind
  include Rules
  attr_reader :player1_name, :player2_name, :game_name, :player1, :player2, :secret_code,
              :display, :gameboard, :codemaker, :codebreaker

  @game_count = 0

  def initialize
    @game_name = "Game #{self.class.count}"
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
    @gameboard = display.gameboard
    "Added #{display} to #{game_name}"
  end

  def start
    return unless players_ready? && display_ready?

    @in_progress = true if @in_progress.nil?
    return display.game_end unless @in_progress

    @turn = 1
    display.introduce_rules
    @secret_code = codemaker.create_code
    codemaker.ishuman ? computer_game_loop : game_loop
  end

  def self.count
    @game_count += 1
  end

  private

  def game_loop
    until turn_limit? || !@in_progress
      display.show_gameboard(@turn)
      play
    end
  end

  def computer_game_loop
    until turn_limit? || !@in_progress
      display.show_gameboard(@turn)
      computer_play
    end
  end

  def computer_play
    display.ask_guess
    make_guess(codebreaker.create_code, @turn)
  end

  def play
    display.ask_guess
    make_guess(gets.chomp.to_s.downcase.split(' '), @turn)
  end

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
end

# This class handles player info and creation.
class Player
  attr_reader :name, :points, :ishuman
  attr_accessor :role, :game

  def initialize(name)
    @name = name.to_s
    @role = nil
    @points = nil
    @game = nil
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
end

# This is a class that handles Human players.
class Human < Player
  include Rules
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
cosmos = Display.new
brave = Human.new('Dave')
hal = Computer.new('HAL')
space_oddysey.add_players(brave, hal)
space_oddysey.attach_display(cosmos)
space_oddysey.start
space_oddysey.start
