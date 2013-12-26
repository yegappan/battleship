" Battleship Game for Vim
" Author: Yegappan Lakshmanan
" Version: 1.0
" Last Modified: 15th March 2008
"

if v:version < 700
    " Vim7 is required for this plugin
    finish
endif

if exists('loaded_battleship')
    " Plugin already loaded
    finish
endif
let loaded_battleship = 1

" Use Vim default 'cpo' setting
let s:cpo_save = &cpo
set cpo&vim

command! -nargs=* BattleShip call battleship#StartGame()

" Restore the 'cpo' setting
let &cpo = s:cpo_save
unlet s:cpo_save
