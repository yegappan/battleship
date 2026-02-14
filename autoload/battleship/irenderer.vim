vim9script

# ============================================================================
# FILE: autoload/battleship/irenderer.vim
# PURPOSE: Interface for main game renderer implementations.
# CONTENTS:
#   - IRenderer interface: Defines contract for game rendering
# KEY METHODS:
#   - Render: Renders complete UI for current game state, returns list of lines
# ============================================================================

import './game.vim' as GameMod

# INTERFACE: IRenderer
# PURPOSE: Contract for main game rendering implementations
# METHODS:
#   - Render(): Return list of strings representing complete game UI for current state
export interface IRenderer
    def Render(game: GameMod.Game): list<string>
endinterface
