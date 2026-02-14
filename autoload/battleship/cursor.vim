vim9script

# ============================================================================
# FILE: autoload/battleship/cursor.vim
# PURPOSE: Manages cursor position and ship orientation during placement phase.
# CONTENTS:
#   - Cursor class: Tracks player's selection position and ship orientation
# KEY STRUCTURES:
#   - position (Position): Current board coordinate (0-9 for 10x10 board)
#   - orientation (Orientation): HORIZONTAL or VERTICAL ship placement
# KEY ALGORITHMS:
#   - Bounded movement: Ensures cursor stays within board boundaries
#   - Orientation toggle: Switches between horizontal and vertical placement
#   - Edge navigation: Methods to jump to board edges
# ============================================================================

import './constants.vim' as C
import './position.vim' as Pos

# CLASS: Cursor
# PURPOSE: Manages cursor position and ship orientation during placement phase
# KEY STRUCTURES:
#   - position (Position): Current board coordinates (0-9 for 10x10 board)
#   - orientation (Orientation): HORIZONTAL or VERTICAL ship placement mode
# KEY ALGORITHMS:
#   - Move(): Updates position with boundary checking to keep cursor in bounds
#   - ToggleOrientation(): Switches between horizontal and vertical orientations
#   - Edge navigation: Methods to jump to board edges (top, bottom, left, right)
export class Cursor
    public var position: Pos.Position
    public var orientation: C.Orientation

    def new()
        this.position = Pos.Position.new(0, 0)
        this.orientation = C.Orientation.HORIZONTAL
    enddef

    def Move(deltaRow: number, deltaCol: number)
        var newRow = this.position.row + deltaRow
        var newCol = this.position.col + deltaCol
        if newRow >= 0 && newRow < C.BOARD_SIZE && newCol >= 0 && newCol < C.BOARD_SIZE
            this.position.row = newRow
            this.position.col = newCol
        endif
    enddef

    def ToggleOrientation()
        if this.orientation == C.Orientation.HORIZONTAL
            this.orientation = C.Orientation.VERTICAL
        else
            this.orientation = C.Orientation.HORIZONTAL
        endif
    enddef

    def MoveToFirstRow()
        this.position.row = 0
    enddef

    def MoveToLastRow()
        this.position.row = C.BOARD_SIZE - 1
    enddef

    def MoveToFirstCol()
        this.position.col = 0
    enddef

    def MoveToLastCol()
        this.position.col = C.BOARD_SIZE - 1
    enddef
endclass
