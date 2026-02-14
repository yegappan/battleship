vim9script

# ============================================================================
# FILE: autoload/battleship/icomputer_ai.vim
# PURPOSE: Interface for computer AI strategy implementations.
# CONTENTS:
#   - IComputerAI interface: Defines contract for AI implementations
# KEY METHODS:
#   - ChooseRandomShot: Returns random valid shot position
#   - ChooseSmartShot: Returns strategically chosen shot based on game state
#   - PlaceShipsRandomly: Randomly places ships on player board
# ============================================================================

import './player.vim' as PlayerMod
import './position.vim' as Pos
import './ship_definition.vim' as SD

# INTERFACE: IComputerAI
# PURPOSE: Contract for computer AI strategy implementations
# METHODS:
#   - ChooseRandomShot(): Return a random valid shot position
#   - ChooseSmartShot(): Return strategically chosen shot based on game analysis
#   - PlaceShipsRandomly(): Place all ships randomly on player board with validation
export interface IComputerAI
    def ChooseRandomShot(player: PlayerMod.Player): Pos.Position
    def ChooseSmartShot(shooter: PlayerMod.Player, target: PlayerMod.Player): Pos.Position
    def PlaceShipsRandomly(player: PlayerMod.Player, shipDefinitions: SD.ShipDefinitions)
endinterface
