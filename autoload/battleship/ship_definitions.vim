vim9script

# ============================================================================
# FILE: autoload/battleship/ship_definitions.vim
# PURPOSE: Immutable configuration defining the standard battleship game ships.
# CONTENTS:
#   - SHIP_DEFINITIONS: Constant list of all game ships (treated as immutable)
# SHIPS:
#   - Carrier (C): 5 cells
#   - Battleship (B): 4 cells
#   - Cruiser (R): 3 cells
#   - Submarine (S): 3 cells
#   - Destroyer (D): 2 cells
#   Total: 17 cells (used for victory detection)
# ============================================================================

import './constants.vim' as C
import './ship_definition.vim' as SD

# Treated as immutable configuration; do not mutate ship definitions at runtime.
export const SHIP_DEFINITIONS: SD.ShipDefinitions = [
    SD.ShipDefinition.new(C.ShipType.CARRIER, 'Carrier', 5, C.SHIP_CARRIER),
    SD.ShipDefinition.new(C.ShipType.BATTLESHIP, 'Battleship', 4, C.SHIP_BATTLESHIP),
    SD.ShipDefinition.new(C.ShipType.CRUISER, 'Cruiser', 3, C.SHIP_CRUISER),
    SD.ShipDefinition.new(C.ShipType.SUBMARINE, 'Submarine', 3, C.SHIP_SUBMARINE),
    SD.ShipDefinition.new(C.ShipType.DESTROYER, 'Destroyer', 2, C.SHIP_DESTROYER)
]
