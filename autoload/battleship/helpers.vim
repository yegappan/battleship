vim9script

# ============================================================================
# FILE: autoload/battleship/helpers.vim
# PURPOSE: Provides utility functions used throughout the game.
# CONTENTS:
#   - CountIf: Counts ships matching a predicate function
#   - GetUnshotPositions: Collects all board positions that haven't been shot
# KEY ALGORITHMS:
#   - Predicate-based filtering: CountIf applies user-defined functions to items
#   - Position collection: Linear scan of board grid to find unshot cells
# ============================================================================

import './constants.vim' as C
import './player.vim' as PlayerMod
import './position.vim' as Pos
import './ship.vim' as ShipMod

export def CountIf(items: ShipMod.ShipList, Predicate: func(ShipMod.Ship): bool): number
    var count = 0
    for item in items
        if Predicate(item)
            count += 1
        endif
    endfor
    return count
enddef

export def GetUnshotPositions(player: PlayerMod.Player): Pos.PositionList
    var positions: Pos.PositionList = []
    for row in range(C.BOARD_SIZE)
        for col in range(C.BOARD_SIZE)
            var pos = Pos.Position.new(row, col)
            if !player.HasAlreadyShot(pos)
                add(positions, pos)
            endif
        endfor
    endfor
    return positions
enddef
