vim9script

# ============================================================================
# FILE: autoload/battleship/ship_definition.vim
# PURPOSE: Defines metadata and properties for ship types.
# CONTENTS:
#   - ShipDefinition class: Immutable metadata for a ship type
#   - ShipDefinitions type: List of ship definitions
# KEY STRUCTURES:
#   - type (ShipType): Enum identifying ship category
#   - name (string): Display name (e.g., "Carrier")
#   - size (number): Grid cells occupied by this ship
#   - symbol (string): Display character on board
# ============================================================================

import './constants.vim' as C

# CLASS: ShipDefinition
# PURPOSE: Immutable metadata container for a ship type
# KEY STRUCTURES:
#   - type (ShipType): Enum identifying ship category (Carrier, Battleship, etc.)
#   - name (string): Display name for UI (e.g., "Carrier")
#   - size (number): Number of grid cells occupied by this ship
#   - symbol (string): Single character displayed on board (C, B, R, S, D)
export class ShipDefinition
    public var type: C.ShipType
    public var name: string
    public var size: number
    public var symbol: string

    def new(type: C.ShipType, name: string, size: number, symbol: string)
        this.type = type
        this.name = name
        this.size = size
        this.symbol = symbol
    enddef
endclass

export type ShipDefinitions = list<ShipDefinition>
