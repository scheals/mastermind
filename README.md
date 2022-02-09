# Mastermind

Mastermind game made in Ruby that tries to be OOP.

Features an infallible AI which probably works like [Swaszek's](https://mathworld.wolfram.com/Mastermind.html) strategy,
that is it eliminates impossible combinations every guess and just randomly picks from what was left.

Specification and instruction from [The Odin Project](https://www.theodinproject.com/paths/full-stack-ruby-on-rails/courses/ruby-programming/lessons/mastermind)

## How to use

For online use go to the [repl](https://replit.com/@scheals/Mastermind?v=1).

For offline use simply download the file to one directory and run it in irb for a game prepared with players.

## Features
* Guessing algorithm that never fails to lose and doesn't cheat
* Create random secret code or randomize parts of it

## Possible future additions

### Internal
* Code clean-up

### Additional Features
* Replay game function
* Tell the guesser what the secret code was if they did not manage to guess it
* Guesses being randomized or randomized in part
* Ability to choose AI difficulty that'll make it "forget" some of its features


## Reflections

What a nightmare. When I thought I had made significant progress when it comes to understanding OOP I came back to josh's review of my Tic-Tac-Toe
and found out that I literally made the same mistake with my `Rules` class. The good/bad part was that I was already done with all the functionality,
so this didn't trip me up and demotivate me mid-project: on the contrary, I felt pretty motivated and energized to fix this.

So how did it turn out? Well, I was happy with the refactor after I finished it but after waking up day after I figured out some things were done wrong.
`Board` class is now doing too much! So once again, I sat down and started refactoring it and being absolutely miserable about it. I am overwhelmed by OOP.
At this point I decided to revert back my attempts at the second refactor and just go with the first one, understanding that without support I am not going
to make the best calls or make them in timely fashion. I *need* pointers and help understanding all this. Thankfully, I have a place to go and ask for it, so that's
what I am going to do.

Overall this is what I learned:
* Programming is hard and grit once again makes you prevail
* Pseudocode is mighty important, just make sure you actually write it correctly/look at it
patiently so you don't make mistakes
* Ruby's built-in methods are absolutely amazing
* How to test tens of thousands Mastermind games in terms of win ratio,
checking out where the AI has done poorly, where the bugs occur. Mind you this was not proper testing, just looping
through 10_000 games plenty of times to pin-point where the failure points were.
[This gist](https://gist.github.com/scheals/172ec36e2e4ea9b144a9bec77f3d1534) documents the journey somewhat.
* Programming can be even more fun than I thought
* I know what I don't know even more than before. I'd love to break classes into their own files for example but given the curriculum I've left it as is for now.
* How to work with Rubocop and thus improve my code quality

## Issues

### Board class does too much
It seems to me that the `Board` class has taken on quite much of what `Mastermind` class should do. I tried to refactor into this direction the second time but as noted earlier
frustration and hopelessness got the better of me - thankfully, honestly, because I realized that Not_green and crespire are even more right than I thought before. If you don't
know things, you have to ask. And asking about the entire thing means showing the entire thing to people so they can give you feedback, even if you think it is inadequate.

### Hint creation code is complicated
`check_matches` and its neighbours are not as good as they should be. I'm passing down lots of arguments and at this point figuring out a variable to put some of those things
into would help a lot with this. This problem arises because I think this is how I think it should be, maybe passing down so many arguments so many times is alright actually?

### Hint reading code is complicated
So while I think it is a lot better than the previous case, similar problem arises: passing down lots of arguments, probably better to put some things into variables.
Maybe let's go back to the *why* of this:

Because I used some helper functions that extract two values out of something, the only way to pass them both at once is to call a function with those two values as arguments.
This cuts down on repetition because if I were to divide up those helper functions so they return one value, I'd have to call them every time I need them. I opted for passing them down multiple times so this does not happen. Not sure if that's the correct way.

### `all_exists` is a nightmare

I had a very hard time making this `reject!` work like I wanted it to. I needed to grab the indexes from particular possibilities and to compare them but this comparison needed to be given to `reject!` to judge. It's supposed to reject those possibilities that have colours in the same positions as the guess. You can see a different version of with `reject!` in `understand_perfects` that makes sure that possibilities that wouldn't have the same amount of perfects are thrown out. I created `flag` because I couldn't simply `break true` to achieve what I wanted.

### I made no effort to use `private` at all
This time around I tried not putting too much pressure onto myself to hide away everything that could be hidden but I kind of managed to get on the other side of the extreme,
I am probably going to fix this somewhere down the line when we come back to these projects to build tests for them but I really, really want pointers in regards to this.

### My class/module descriptions are rather lacking
Not big of a problem since I wasn't really taught/interested in how to describe them but I'd love some pointers anyway - just telling me "It comes later down the line" is absolutely fine.

## Acknowledgements
Rubyists from TOP Discord for supporting me on this journey.

README layout from [Chargrilled Chook](https://github.com/ChargrilledChook)
