vim9script

# ============================================================================
# FILE: autoload/battleship/main.vim
# PURPOSE: Main game loop and event dispatcher orchestrating UI and user input.
# CONTENTS:
#   - Game initialization and renderer setup
#   - Event handlers for user input and game state changes
#   - Buffer rendering with syntax highlighting
# KEY FUNCTIONS:
#   - InitializeGame: Creates game and renderer instances
#   - RenderToBuffer: Clears buffer and applies rendered game state
#   - ApplySyntaxHighlighting: Applies Vim highlight groups to UI elements
#   - Input handlers: MoveUp/Down/Left/Right, RotateShip, SelectAction
# KEY ALGORITHMS:
#   - Game phase-aware input: Handlers behave differently based on current phase
#   - Syntax highlighting: Uses regex patterns with priority to highlight UI elements
# ============================================================================

import './constants.vim' as C
import './game.vim' as GameMod
import './renderer.vim' as RendererMod

var g_game: GameMod.Game
var g_renderer: RendererMod.Renderer

def InitializeGame()
    g_game = GameMod.Game.new()
    g_renderer = RendererMod.Renderer.new()
enddef

def RenderToBuffer()
    setlocal modifiable
    :%delete _
    var lines = g_renderer.Render(g_game)
    setline(1, lines)
    ApplySyntaxHighlighting()
    setlocal nomodifiable
    setlocal nomodified
enddef

def ApplySyntaxHighlighting()
    # Clear existing matches
    silent! call clearmatches()

    # Water and empty cells
    matchadd('BattleshipWater', '≈')
    matchadd('BattleshipEmpty', '◦')

    # Sunk ships (higher priority than regular hits)
    matchadd('BattleshipSunk', '✗', 15)

    # Hit and Miss
    matchadd('BattleshipHit', '✓')
    matchadd('BattleshipMiss', '◇')

    # Ship symbols - only within grid context and only when grid is displayed
    if g_game.phase == C.GamePhase.PLACEMENT || g_game.phase == C.GamePhase.BATTLE
        matchadd('BattleshipShip', '\%>7l\%<18l[CBSRD]')
    endif

    # Preview
    matchadd('BattleshipPreview', '★')

    # Cursor
    matchadd('BattleshipCursor', '◉')
enddef

# Input handlers
def MoveUp()
    if g_game.phase == C.GamePhase.LEVEL_SELECTION
        g_game.PreviousLevel()
    elseif g_game.phase == C.GamePhase.VARIANT_SELECTION
        g_game.PreviousVariant()
    else
        g_game.cursor.Move(-1, 0)
    endif
    RenderToBuffer()
enddef

def MoveDown()
    if g_game.phase == C.GamePhase.LEVEL_SELECTION
        g_game.SelectLevel()
    elseif g_game.phase == C.GamePhase.VARIANT_SELECTION
        g_game.SelectVariant()
    else
        g_game.cursor.Move(1, 0)
    endif
    RenderToBuffer()
enddef

def MoveLeft()
    g_game.cursor.Move(0, -1)
    RenderToBuffer()
enddef

def MoveRight()
    g_game.cursor.Move(0, 1)
    RenderToBuffer()
enddef

def RotateShip()
    if g_game.phase == C.GamePhase.PLACEMENT
        g_game.cursor.ToggleOrientation()
        RenderToBuffer()
    endif
enddef

def SelectAction()
    if g_game.phase == C.GamePhase.LEVEL_SELECTION
        g_game.ConfirmLevel()
        RenderToBuffer()
    elseif g_game.phase == C.GamePhase.VARIANT_SELECTION
        g_game.ConfirmVariant()
        RenderToBuffer()
    elseif g_game.phase == C.GamePhase.PLACEMENT
        g_game.PlacePlayerShip()
        RenderToBuffer()
    elseif g_game.phase == C.GamePhase.BATTLE
        g_game.PlayerShoot()
        RenderToBuffer()
    endif
enddef

def EndTurn()
    if g_game.phase == C.GamePhase.BATTLE && g_game.playerShotsUsed > 0
        g_game.EndPlayerTurn()
        RenderToBuffer()
    endif
enddef

def NextVariant()
    if g_game.phase == C.GamePhase.VARIANT_SELECTION
        g_game.SelectVariant()
        RenderToBuffer()
    endif
enddef

def PrevVariant()
    if g_game.phase == C.GamePhase.VARIANT_SELECTION
        g_game.PreviousVariant()
        RenderToBuffer()
    endif
enddef

def MoveToFirstRow()
    g_game.cursor.MoveToFirstRow()
    RenderToBuffer()
enddef

def MoveToLastRow()
    g_game.cursor.MoveToLastRow()
    RenderToBuffer()
enddef

def MoveToFirstCol()
    g_game.cursor.MoveToFirstCol()
    RenderToBuffer()
enddef

def MoveToLastCol()
    g_game.cursor.MoveToLastCol()
    RenderToBuffer()
enddef

def NewGame()
    g_game.Reset()
    RenderToBuffer()
enddef

def QuitGame()
    bwipeout!
    enew
enddef

# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

export def StartBattleship()
    # Create new buffer
    enew
    setlocal buftype=nofile
    setlocal bufhidden=wipe
    setlocal noswapfile
    setlocal nowrap
    setlocal nonumber
    setlocal norelativenumber
    file Battleship

    # Set up key mappings
    nnoremap <buffer> k <ScriptCmd>MoveUp()<CR>
    nnoremap <buffer> j <ScriptCmd>MoveDown()<CR>
    nnoremap <buffer> h <ScriptCmd>MoveLeft()<CR>
    nnoremap <buffer> l <ScriptCmd>MoveRight()<CR>
    nnoremap <buffer> <Up> <ScriptCmd>MoveUp()<CR>
    nnoremap <buffer> <Down> <ScriptCmd>MoveDown()<CR>
    nnoremap <buffer> <Left> <ScriptCmd>MoveLeft()<CR>
    nnoremap <buffer> <Right> <ScriptCmd>MoveRight()<CR>
    nnoremap <buffer> H <ScriptCmd>MoveToFirstRow()<CR>
    nnoremap <buffer> L <ScriptCmd>MoveToLastRow()<CR>
    nnoremap <buffer> 0 <ScriptCmd>MoveToFirstCol()<CR>
    nnoremap <buffer> $ <ScriptCmd>MoveToLastCol()<CR>
    nnoremap <buffer> <Home> <ScriptCmd>MoveToFirstCol()<CR>
    nnoremap <buffer> <End> <ScriptCmd>MoveToLastCol()<CR>
    nnoremap <buffer> <PageUp> <ScriptCmd>MoveToFirstRow()<CR>
    nnoremap <buffer> <PageDown> <ScriptCmd>MoveToLastRow()<CR>
    nnoremap <buffer> <CR> <ScriptCmd>SelectAction()<CR>
    nnoremap <buffer> s <ScriptCmd>SelectAction()<CR>
    nnoremap <buffer> r <ScriptCmd>RotateShip()<CR>
    nnoremap <buffer> n <ScriptCmd>NewGame()<CR>
    nnoremap <buffer> q <ScriptCmd>QuitGame()<CR>
    nnoremap <buffer> <Esc> <ScriptCmd>EndTurn()<CR>

    # Set up syntax highlighting
    silent! highlight BattleshipWater ctermfg=6 guifg=#00BFFF cterm=bold gui=bold
    silent! highlight BattleshipEmpty ctermfg=8 guifg=#808080 cterm=NONE gui=NONE
    silent! highlight BattleshipHit ctermfg=1 guifg=#FF4444 cterm=bold gui=bold
    silent! highlight BattleshipMiss ctermfg=3 guifg=#FFD700 cterm=bold gui=bold
    silent! highlight BattleshipShip ctermfg=2 guifg=#00DD00 cterm=bold gui=bold
    silent! highlight BattleshipPreview ctermfg=4 guifg=#0066FF cterm=bold gui=bold
    silent! highlight BattleshipSunk ctermfg=5 guifg=#FF00FF cterm=bold gui=bold
    silent! highlight BattleshipCursor ctermfg=7 ctermbg=4 guifg=#FFFFFF guibg=#0066FF cterm=bold gui=bold

    # Initialize and render
    InitializeGame()
    RenderToBuffer()
enddef
