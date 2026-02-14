vim9script

# ============================================================================
# FILE: autoload/battleship/ship.vim
# PURPOSE: Represents a single ship entity in the battleship game.
# CONTENTS:
#   - Ship class: Manages ship state including position, definition, and hit tracking
#   - ShipList type: List of Ship objects
# KEY STRUCTURES:
#   - positions (PositionList): Array of grid coordinates occupied by the ship
#   - hits (number): Counter tracking damage received
# KEY ALGORITHMS:
#   - Ship placement: Places ship on board in horizontal or vertical orientation
#   - Hit detection: Checks if given position matches any ship cell
#   - Sinking: Determines if ship has received enough hits to sink
# ============================================================================

import './constants.vim' as C
import './position.vim' as Pos
import './ship_definition.vim' as SD

# CLASS: Ship
# PURPOSE: Represents a single ship entity with placement and hit tracking
# KEY STRUCTURES:
#   - definition (ShipDefinition): Ship metadata (type, name, size, symbol)
#   - positions (PositionList): Array of board coordinates occupied by this ship
#   - hits (number): Count of times this ship has been hit
# KEY ALGORITHMS:
#   - Place(): Calculates all positions for ship based on start coordinate and orientation
#   - IsHit(): Linear search to check if given position matches any ship cell
#   - IsSunk(): Determines if ship has received enough damage to be destroyed
export class Ship
    public var definition: SD.ShipDefinition
    public var positions: Pos.PositionList
    public var hits: number

    def new(definition: SD.ShipDefinition)
        this.definition = definition
        this.positions = []
        this.hits = 0
    enddef

    def Place(startRow: number, startCol: number, orientation: C.Orientation)
        this.positions = []
        for i in range(this.definition.size)
            if orientation == C.Orientation.HORIZONTAL
                add(this.positions, Pos.Position.new(startRow, startCol + i))
            else
                add(this.positions, Pos.Position.new(startRow + i, startCol))
            endif
        endfor
    enddef

    def IsHit(pos: Pos.Position): bool
        for p in this.positions
            if p.Equals(pos)
                return true
            endif
        endfor
        return false
    enddef

    def RegisterHit()
        this.hits += 1
    enddef

    def IsSunk(): bool
        return this.hits >= this.definition.size
    enddef

    def GetStatus(): string
        if this.IsSunk()
            return 'SUNK'
        else
            return printf('%d/%d hits', this.hits, this.definition.size)
        endif
    enddef
endclass

export type ShipList = list<Ship>
