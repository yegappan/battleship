vim9script

# ============================================================================
# FILE: autoload/battleship/player.vim
# PURPOSE: Represents a player entity with ship collection and shot tracking.
# CONTENTS:
#   - Player class: Manages one player's board, ships, and combat statistics
# KEY STRUCTURES:
#   - board (Board): Own ships and placement state
#   - ships (ShipList): Collection of placed ships
#   - shotBoard (Board): Opponent shots on this player's board
#   - hits (number): Total successful shots against opponent
# KEY ALGORITHMS:
#   - Shot reception: Records incoming shots, finds hit ships, registers damage
#   - Shot tracking: Maintains record of shots fired at opponent
#   - Victory detection: Checks if all opponent ships sunk (reach total ship cells)
#   - Ship lookup: Finds ship matching a shot position
# ============================================================================

import './board.vim' as BoardMod
import './constants.vim' as C
import './position.vim' as Pos
import './ship.vim' as ShipMod

# CLASS: Player
# PURPOSE: Represents a player with board, ships, and combat statistics
# KEY STRUCTURES:
#   - board (Board): Grid with placed ships
#   - ships (ShipList): Collection of Ship objects
#   - shotBoard (Board): Grid tracking shots fired at opponent
#   - hits (number): Count of successful shots against opponent
#   - isComputer (bool): Flag indicating if this is AI player
# KEY ALGORITHMS:
#   - ReceiveShot(): Determines if shot hits and registers damage on matching ship
#   - RecordShot(): Updates shotBoard with hit/miss result
#   - AllShipsSunk(): Checks if total hits equal ship cell count for victory
#   - GetSunkShip(): Finds sunk ship at given position for sinking announcement
export class Player
    public var name: string
    public var board: BoardMod.Board
    public var ships: ShipMod.ShipList
    public var shotBoard: BoardMod.Board
    public var hits: number
    public var isComputer: bool

    def new(name: string, isComputer: bool)
        this.name = name
        this.isComputer = isComputer
        this.board = BoardMod.Board.new(C.BOARD_SIZE)
        this.shotBoard = BoardMod.Board.new(C.BOARD_SIZE)
        this.ships = []
        this.hits = 0
    enddef

    def AddShip(ship: ShipMod.Ship)
        add(this.ships, ship)
    enddef

    def ReceiveShot(pos: Pos.Position): bool
        var shipSymbol = this.board.GetCell(pos.row, pos.col)
        var isHit = shipSymbol != C.CELL_WATER

        if isHit
            this.hits += 1
            for ship in this.ships
                if ship.IsHit(pos)
                    ship.RegisterHit()
                    return true
                endif
            endfor
        endif
        return isHit
    enddef

    def RecordShot(pos: Pos.Position, isHit: bool)
        this.shotBoard.SetCell(pos.row, pos.col, isHit ? C.CELL_HIT : C.CELL_MISS)
    enddef

    def HasAlreadyShot(pos: Pos.Position): bool
        return this.shotBoard.GetCell(pos.row, pos.col) != C.CELL_WATER
    enddef

    def HasAnyUnshot(): bool
        for row in this.shotBoard.grid
            for cell in row
                if cell == C.CELL_WATER
                    return true
                endif
            endfor
        endfor
        return false
    enddef

    def GetSunkShip(pos: Pos.Position): ShipMod.Ship
        for ship in this.ships
            if ship.IsHit(pos) && ship.IsSunk()
                return ship
            endif
        endfor
        return null_object
    enddef

    def AllShipsSunk(): bool
        return this.hits >= C.TOTAL_SHIP_CELLS
    enddef
endclass
