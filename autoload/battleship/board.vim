vim9script

# ============================================================================
# FILE: autoload/battleship/board.vim
# PURPOSE: Represents a 10x10 game board for tracking ship placement and shots.
# CONTENTS:
#   - Board class: Manages the game grid and ship placement validation
#   - BoardRow, BoardGrid types: 2D grid representations
# KEY STRUCTURES:
#   - grid (BoardGrid): 2D array of cell strings representing board state
#   - size (number): Board dimensions (typically 10x10)
# KEY ALGORITHMS:
#   - Ship placement validation: Checks bounds and overlap before placing ships
#   - Cell state management: Updates cells for ships, hits, and misses
# ============================================================================

import './constants.vim' as C
import './position.vim' as Pos
import './ship.vim' as ShipMod

export type BoardRow = list<string>
export type BoardGrid = list<BoardRow>

# CLASS: Board
# PURPOSE: Represents a 10x10 game board for tracking ship placement and shots
# KEY STRUCTURES:
#   - grid (BoardGrid): 2D array of cell strings representing board state
#   - size (number): Board dimensions (typically 10x10)
# KEY ALGORITHMS:
#   - CanPlaceShip(): Validates ship placement with boundary and overlap checking
#   - PlaceShip(): Updates grid with ship symbol at specified positions
export class Board
    public var grid: BoardGrid
    public var size: number

    def new(size: number)
        this.size = size
        this.grid = []
        for i in range(size)
            var row: BoardRow = []
            for j in range(size)
                add(row, C.CELL_WATER)
            endfor
            add(this.grid, row)
        endfor
    enddef

    def GetCell(row: number, col: number): string
        return this.grid[row][col]
    enddef

    def SetCell(row: number, col: number, value: string)
        this.grid[row][col] = value
    enddef

    def CanPlaceShip(row: number, col: number, size: number, orientation: C.Orientation): bool
        if orientation == C.Orientation.HORIZONTAL
            if col + size > this.size
                return false
            endif
            for i in range(size)
                if this.grid[row][col + i] != C.CELL_WATER
                    return false
                endif
            endfor
        else
            if row + size > this.size
                return false
            endif
            for i in range(size)
                if this.grid[row + i][col] != C.CELL_WATER
                    return false
                endif
            endfor
        endif
        return true
    enddef

    def PlaceShip(ship: ShipMod.Ship, row: number, col: number, orientation: C.Orientation)
        ship.Place(row, col, orientation)
        for pos in ship.positions
            this.grid[pos.row][pos.col] = ship.definition.symbol
        endfor
    enddef
endclass
