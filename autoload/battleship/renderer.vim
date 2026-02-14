vim9script

# ============================================================================
# FILE: autoload/battleship/renderer.vim
# PURPOSE: Comprehensive rendering engine for all game UI elements.
# CONTENTS:
#   - Renderer class: Implements all rendering interfaces
#   - Supports level/variant selection, ship placement, and battle phases
#   - Renders boards, statistics, menus, and game status
# KEY STRUCTURES:
#   - Board ASCII art: Uses box drawing characters (╔═╗║╚╝)
#   - Ship positioning visualization: Shows placed ships and cursor preview
#   - Hit/miss visualization: Displays shot results on opponent board
# KEY METHODS:
#   - RenderPlacementBoard: Shows player board during placement with preview
#   - RenderBattleBoards: Shows both boards in battle phase
#   - RenderStats: Shows ship status and game statistics
#   - RenderTitle/LevelSelection/VariantSelection: Menu rendering
# ============================================================================

import './constants.vim' as C
import './game.vim' as GameMod
import './player.vim' as PlayerMod
import './irenderer.vim' as IRenderer
import './iboard_renderer.vim' as IBoardRenderer
import './istatus_renderer.vim' as IStatusRenderer

# CLASS: Renderer
# PURPOSE: Comprehensive UI rendering engine implementing all rendering interfaces
# IMPLEMENTS: IRenderer, IBoardRenderer, IStatusRenderer
# KEY STRUCTURES:
#   - Board ASCII art: Uses box drawing characters (╔═╗║╚╝) for visual layout
#   - Ship positioning visualization: Shows placed/sunk ships and cursor preview
#   - Hit/miss visualization: Displays shot results on opponent board
# KEY METHODS:
#   - Render(): Main entry point producing complete UI for current game state
#   - RenderPlacementBoard(): Shows player board with ship preview during placement
#   - RenderBattleBoards(): Displays both player and opponent boards side-by-side
#   - RenderStats(): Shows ship status, damage, and game statistics
#   - Phase-specific renderers: Level selection, variant selection, game over
export class Renderer implements IRenderer.IRenderer, IBoardRenderer.IBoardRenderer, IStatusRenderer.IStatusRenderer
    def IsSunkenShipCell(player: PlayerMod.Player, row: number, col: number): bool
        # Check if this cell contains a ship that is sunk
        for ship in player.ships
            if ship.IsSunk()
                for pos in ship.positions
                    if pos.row == row && pos.col == col
                        return true
                    endif
                endfor
            endif
        endfor
        return false
    enddef

    def RenderTitle(): list<string>
        var lines: list<string> = []
        add(lines, '╔════════════════════════════════════════════════════════════════════╗')
        add(lines, '║                      BATTLESHIP GAME                               ║')
        add(lines, '╚════════════════════════════════════════════════════════════════════╝')
        add(lines, '')
        return lines
    enddef

    def RenderVariantSelection(game: GameMod.Game): list<string>
        var lines: list<string> = []

        add(lines, '')
        add(lines, '     ╔════════════════════════════════════════════╗')
        add(lines, '     ║         SELECT GAME VARIANT                ║')
        add(lines, '     ╚════════════════════════════════════════════╝')
        add(lines, '')

        for i in range(len(C.VARIANT_OPTIONS))
            var marker = i == game.selectedVariantIndex ? '▶ ' : '  '
            var line = printf('     %s[%d] %s', marker, i + 1, C.VARIANT_OPTIONS[i][0])
            add(lines, line)
            add(lines, printf('         %s', C.VARIANT_OPTIONS[i][1]))
            add(lines, '')
        endfor

        add(lines, '     Use ↑/↓ or j/k to select, Enter or s to confirm')
        add(lines, '')

        return lines
    enddef

    def RenderLevelSelection(game: GameMod.Game): list<string>
        var lines: list<string> = []

        add(lines, '')
        add(lines, '     ╔════════════════════════════════════════════╗')
        add(lines, '     ║         SELECT PLAYER LEVEL               ║')
        add(lines, '     ╚════════════════════════════════════════════╝')
        add(lines, '')

        for i in range(len(C.LEVEL_OPTIONS))
            var marker = i == game.selectedLevelIndex ? '▶ ' : '  '
            var line = printf('     %s[%d] %s', marker, i + 1, C.LEVEL_OPTIONS[i][0])
            add(lines, line)
            add(lines, printf('         %s', C.LEVEL_OPTIONS[i][1]))
            add(lines, '')
        endfor

        add(lines, '     Use ↑/↓ or j/k to select, Enter or s to confirm')
        add(lines, '')

        return lines
    enddef

    def RenderPlacementBoard(game: GameMod.Game): list<string>
        var lines: list<string> = []
        add(lines, '                    YOUR BOARD')
        add(lines, '      0 1 2 3 4 5 6 7 8 9')
        add(lines, '    ┌────────────────────┐')

        for i in range(C.BOARD_SIZE)
            var line = printf('  %d │', i)
            for j in range(C.BOARD_SIZE)
                var cell = game.player.board.GetCell(i, j)
                var showPreview = false

                # Show preview of ship placement
                var shipDef = game.GetCurrentShipDef()
                if shipDef != null_object
                    var cursorPos = game.cursor.position
                    if game.cursor.orientation == C.Orientation.HORIZONTAL
                        if i == cursorPos.row && j >= cursorPos.col && j < cursorPos.col + shipDef.size
                            showPreview = true
                        endif
                    else
                        if j == cursorPos.col && i >= cursorPos.row && i < cursorPos.row + shipDef.size
                            showPreview = true
                        endif
                    endif

                    if showPreview && game.player.board.CanPlaceShip(cursorPos.row, cursorPos.col,
                                                                      shipDef.size, game.cursor.orientation)
                        line ..= C.CELL_PREVIEW .. ' '
                    else
                        line ..= (cell == C.CELL_WATER ? C.CELL_EMPTY .. ' ' : cell .. ' ')
                    endif
                else
                    line ..= (cell == C.CELL_WATER ? C.CELL_EMPTY .. ' ' : cell .. ' ')
                endif
            endfor
            line ..= '│'
            add(lines, line)
        endfor
        add(lines, '    └────────────────────┘')
        return lines
    enddef

    def RenderBattleBoards(game: GameMod.Game): list<string>
        var lines: list<string> = []
        add(lines, '       ENEMY WATERS                      YOUR WATERS')
        add(lines, '    0 1 2 3 4 5 6 7 8 9              0 1 2 3 4 5 6 7 8 9')
        add(lines, '  ┌────────────────────┐          ┌────────────────────┐')

        for i in range(C.BOARD_SIZE)
            var line = printf('%d │', i)
            for j in range(C.BOARD_SIZE)
                var cell = game.player.shotBoard.GetCell(i, j)
                if i == game.cursor.position.row && j == game.cursor.position.col && game.phase == C.GamePhase.BATTLE
                    line ..= C.CELL_CURSOR .. ' '
                else
                    line ..= (cell == C.CELL_WATER ? C.CELL_EMPTY .. ' ' : cell .. ' ')
                endif
            endfor
            line ..= printf('│        %d │', i)
            for j in range(C.BOARD_SIZE)
                var playerCell = game.player.board.GetCell(i, j)
                var shotCell = game.computer.shotBoard.GetCell(i, j)
                if shotCell != C.CELL_WATER
                    # Check if this is part of a sunk ship and display accordingly
                    if shotCell == C.CELL_HIT && this.IsSunkenShipCell(game.player, i, j)
                        line ..= '✗ '
                    else
                        line ..= shotCell .. ' '
                    endif
                else
                    line ..= (playerCell == C.CELL_WATER ? C.CELL_EMPTY .. ' ' : playerCell .. ' ')
                endif
            endfor
            line ..= '│'
            add(lines, line)
        endfor
        add(lines, '  └────────────────────┘          └────────────────────┘')
        return lines
    enddef

    def RenderStats(game: GameMod.Game): list<string>
        var lines: list<string> = []
        add(lines, '')
        add(lines, '═══════════════════════════════════════════════════════════════════════')

        # Game variant info
        var variantOption = game.GetVariantOption()
        var levelOption = game.GetLevelOption()
        add(lines, printf('LEVEL: %s  |  VARIANT: %s', levelOption[0], variantOption[0]))

        if game.phase == C.GamePhase.BATTLE
            var playerShotsAllowed = game.GetPlayerShotsAllowed()
            add(lines, printf('YOUR SHOTS: %d/%d used', game.playerShotsUsed, playerShotsAllowed))
        endif

        add(lines, printf('  Your Hits: %d/%d  |  Computer Hits: %d/%d',
                         game.player.hits, C.TOTAL_SHIP_CELLS,
                         game.computer.hits, C.TOTAL_SHIP_CELLS))

        # Player fleet status
        add(lines, '')
        add(lines, 'YOUR FLEET:')
        for ship in game.player.ships
            add(lines, printf('  %s: %s', ship.definition.name, ship.GetStatus()))
        endfor

        # Computer fleet status
        if len(game.computer.ships) > 0
            add(lines, '')
            add(lines, 'ENEMY FLEET:')
            for ship in game.computer.ships
                var status = ship.IsSunk() ? 'SUNK' : 'AFLOAT'
                add(lines, printf('  %s (%d): %s', ship.definition.name, ship.definition.size, status))
            endfor
        endif

        return lines
    enddef

    def RenderFooter(game: GameMod.Game): list<string>
        var lines: list<string> = []
        add(lines, '')
        add(lines, '═══════════════════════════════════════════════════════════════════════')
        add(lines, printf('MESSAGE: %s', game.message))
        add(lines, '')

        if game.phase == C.GamePhase.LEVEL_SELECTION
            add(lines, 'CONTROLS: ↑/↓ or j/k=select | Enter/s=confirm')
        elseif game.phase == C.GamePhase.VARIANT_SELECTION
            add(lines, 'CONTROLS: ↑/↓ or j/k=select | Enter/s=confirm')
        elseif game.phase == C.GamePhase.PLACEMENT
            add(lines, 'CONTROLS: ↑↓←→ or hjkl=move | Home/End/PgUp/PgDn=edges | Enter/s=place | r=rotate | n=new | q=quit')
        else  # BATTLE
            var controls = '↑↓←→ or hjkl=aim | Home/End/PgUp/PgDn=edges | Enter/s=shoot'
            if game.playerShotsUsed > 0
                var shotsAllowed = game.GetPlayerShotsAllowed()
                if game.playerShotsUsed < shotsAllowed
                    controls ..= ' | ESC=end turn'
                endif
            endif
            controls ..= ' | n=new | q=quit'
            add(lines, 'CONTROLS: ' .. controls)
        endif

        add(lines, '═══════════════════════════════════════════════════════════════════════')
        return lines
    enddef

    def Render(game: GameMod.Game): list<string>
        var lines: list<string> = []

        lines->extend(this.RenderTitle())

        if game.phase == C.GamePhase.LEVEL_SELECTION
            lines->extend(this.RenderLevelSelection(game))
        elseif game.phase == C.GamePhase.VARIANT_SELECTION
            lines->extend(this.RenderVariantSelection(game))
        elseif game.phase == C.GamePhase.PLACEMENT
            lines->extend(this.RenderPlacementBoard(game))
        else
            lines->extend(this.RenderBattleBoards(game))
        endif

        if game.phase != C.GamePhase.LEVEL_SELECTION && game.phase != C.GamePhase.VARIANT_SELECTION
            lines->extend(this.RenderStats(game))
        endif

        lines->extend(this.RenderFooter(game))

        return lines
    enddef
endclass
