vim9script

# ============================================================================
# FILE: autoload/battleship/position.vim
# PURPOSE: Represents a board coordinate position with utility methods.
# CONTENTS:
#   - Position class: Immutable coordinate pair with equality checking
#   - PositionList type: List of Position objects
# KEY STRUCTURES:
#   - row (number): Y-coordinate (0-9 on standard board)
#   - col (number): X-coordinate (0-9 on standard board)
# KEY ALGORITHMS:
#   - Position equality: Compares row and column values
# ============================================================================

# CLASS: Position
# PURPOSE: Represents an immutable board coordinate pair
# KEY STRUCTURES:
#   - row (number): Y-coordinate (0-9 on standard 10x10 board)
#   - col (number): X-coordinate (0-9 on standard 10x10 board)
# KEY ALGORITHMS:
#   - Equals(): Compares row and column values for coordinate matching
export class Position
    public var row: number
    public var col: number

    def new(row: number, col: number)
        this.row = row
        this.col = col
    enddef

    def Equals(other: Position): bool
        return this.row == other.row && this.col == other.col
    enddef
endclass

export type PositionList = list<Position>
