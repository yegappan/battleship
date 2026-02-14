vim9script

# ============================================================================
# FILE: plugin/battleship.vim
# PURPOSE: Plugin entry point that defines Vim commands and initializes the game.
# CONTENTS:
#   - :Battleship and :BattleshipNew commands for starting the game
#   - Auto-start logic when file is sourced directly
# KEY FUNCTIONS:
#   - StartBattleship: Initializes and launches the battleship game
# ============================================================================

import '../autoload/battleship/main.vim' as Battleship

export def StartBattleship()
    Battleship.StartBattleship()
enddef

command! Battleship StartBattleship()
command! BattleshipNew StartBattleship()

# Auto-start if sourced directly
if expand('%:p') == expand('<sfile>:p')
    StartBattleship()
endif
