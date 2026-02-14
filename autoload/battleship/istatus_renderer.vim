vim9script

# ============================================================================
# FILE: autoload/battleship/istatus_renderer.vim
# PURPOSE: Interface for rendering game status and statistics information.
# CONTENTS:
#   - IStatusRenderer interface: Defines contract for status rendering
# KEY METHODS:
#   - RenderStats: Renders player statistics and ship status
#   - RenderFooter: Renders game footer with current messages and instructions
# ============================================================================

import './game.vim' as GameMod

# INTERFACE: IStatusRenderer
# PURPOSE: Contract for status and statistics rendering implementations
# METHODS:
#   - RenderStats(): Return list of strings showing player statistics and ship status
#   - RenderFooter(): Return list of strings showing game messages and instructions
export interface IStatusRenderer
    def RenderStats(game: GameMod.Game): list<string>
    def RenderFooter(game: GameMod.Game): list<string>
endinterface
