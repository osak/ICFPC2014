# Team "Kokoro Pyon-pyon"

## Contents
- solution: Our AI
- code: Code used to generate AI

## Main Strategy of Lambda-Man AI
UCT Algorithm.

## Main Stratregy of Ghost AI
Ghost AI generally traces Lambda-man.
We have a two types of strategy, only trace and trace the expected position of lambda-man.


## Main Strategy of Coding
At the first glance, we noticed the importance of GCC compiler because
it is appearently kind of a Lisp machine (Unfortunately we didn't
know the word "SECD-machine" at that time.)

We implemented the compiler from Scheme-like language (we called this
language "rabbit") to GCC assembly.
The compiler is written in Ruby language and its code is located at
code/compiler and executable script is code/compiler/chino.rb .
Rabbit script file is in code/rabbit .

After ending the lightning round, the importance of implementing ghost
AI is raised, and we implemented preprocessor for GHC assembly.
It has just two functionality: replace constants and resolve jump
addresses.
Despite of its simplisity, it is amazingly helpful.
Preprocessor is code/bin/tippy.rb and the DSL is in code/mofu .

./bin/rize.rb and ./bin/syaro.rb are GCC emulator.
