vim9script
# Battleship Game Plugin for Vim9
# Naval combat strategy game - sink opponent ships before losing yours
# Requires: Vim 9.0+

if exists('g:loaded_battleship')
  finish
endif
g:loaded_battleship = 1

import autoload '../autoload/battleship/main.vim' as Battleship

# Default difficulty level
if !exists('g:battleship_difficulty')
  g:battleship_difficulty = 'novice'
endif

# Command to start the game
command! Battleship call Battleship.StartBattleship()
