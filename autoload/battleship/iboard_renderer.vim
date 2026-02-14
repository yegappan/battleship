vim9script

# ============================================================================
# FILE: autoload/battleship/iboard_renderer.vim
# PURPOSE: Interface for board rendering implementations.
# CONTENTS:
#   - IBoardRenderer interface: Defines contract for board rendering
# KEY METHODS:
#   - RenderPlacementBoard: Renders board during ship placement phase
#   - RenderBattleBoards: Renders both player and opponent boards during battle
# ============================================================================

import './game.vim' as GameMod

# INTERFACE: IBoardRenderer
# PURPOSE: Contract for board rendering implementations
# METHODS:
#   - RenderPlacementBoard(): Called during ship placement phase to show player board
#   - RenderBattleBoards(): Called during battle phase to show both boards
export interface IBoardRenderer
    def RenderPlacementBoard(game: GameMod.Game): list<string>
    def RenderBattleBoards(game: GameMod.Game): list<string>
endinterface
