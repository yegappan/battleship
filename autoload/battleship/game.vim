vim9script

# ============================================================================
# FILE: autoload/battleship/game.vim
# PURPOSE: Central game state and logic orchestration across all game phases.
# CONTENTS:
#   - Game class: Manages game state, player coordination, and turn mechanics
# KEY STATE:
#   - phase: Current game phase (selection, placement, battle, etc.)
#   - variant: Selected game variation affecting shot mechanics
#   - playerLevel: AI difficulty setting (NOVICE or EXPERT)
#   - player/computer: Player objects tracking ships and shots
#   - Shot tracking: Counters for shots used and hits per turn
# KEY ALGORITHMS:
#   - Game flow: Transitions through levels, variants, placement, and battle phases
#   - Ship placement validation: Checks bounds and overlap before confirming placement
#   - Turn mechanics: Handles shot firing with variant-specific rules (bonus shots, etc.)
#   - Win/loss detection: Checks if all opponent ships sunk
# ============================================================================

import './computer_ai.vim' as AI
import './constants.vim' as C
import './cursor.vim' as CursorMod
import './helpers.vim' as Helpers
import './icomputer_ai.vim' as IAI
import './player.vim' as PlayerMod
import './ship.vim' as ShipMod
import './ship_definition.vim' as SD
import './ship_definitions.vim' as ShipDefs

# CLASS: Game
# PURPOSE: Central game controller managing state and logic across all game phases
# KEY STRUCTURES:
#   - phase (GamePhase): Current game state (selection, placement, battle, gameover)
#   - player/computer (Player): Player objects with boards and ships
#   - cursor (Cursor): Position and orientation for ship placement
#   - variant (GameVariation): Game mode affecting shot mechanics
#   - playerLevel (PlayerLevel): AI difficulty (NOVICE or EXPERT)
# KEY ALGORITHMS:
#   - Reset(): Initializes game state and places computer ships randomly
#   - PlacePlayerShip(): Validates and places player's ship, advances placement
#   - PlayerShoot()/ComputerShoot(): Handles shot firing based on variant rules
#   - Phase transitions: Moves game through level selection → variant → placement → battle
export class Game
    public var phase: C.GamePhase
    public var variant: C.GameVariation
    public var selectedVariantIndex: number
    public var playerLevel: C.PlayerLevel
    public var selectedLevelIndex: number
    public var player: PlayerMod.Player
    public var computer: PlayerMod.Player
    public var cursor: CursorMod.Cursor
    public var shipDefinitions: SD.ShipDefinitions
    public var currentShipIndex: number
    public var message: string
    public var ai: IAI.IComputerAI
    public var playerShotsUsed: number
    public var playerLastShotWasHit: bool
    public var playerHitsThisTurn: number
    public var computerShotsUsed: number
    public var computerLastShotWasHit: bool
    public var computerHitsThisTurn: number

    def new()
        this.shipDefinitions = ShipDefs.SHIP_DEFINITIONS
        this.ai = AI.ComputerAI.new()
        this.Reset()
    enddef

    def Reset()
        this.phase = C.GamePhase.LEVEL_SELECTION
        this.selectedLevelIndex = 0
        this.playerLevel = C.PlayerLevel.NOVICE
        this.selectedVariantIndex = 0
        this.variant = C.GameVariation.ONE_SHOT
        this.player = PlayerMod.Player.new('Player', false)
        this.computer = PlayerMod.Player.new('Computer', true)
        this.cursor = CursorMod.Cursor.new()
        this.currentShipIndex = 0
        this.playerShotsUsed = 0
        this.playerLastShotWasHit = false
        this.playerHitsThisTurn = 0
        this.computerShotsUsed = 0
        this.computerLastShotWasHit = false
        this.computerHitsThisTurn = 0
        this.message = 'Select player level: (j) next, (k) prev, (Enter/s) confirm'

        # Place computer ships
        this.ai.PlaceShipsRandomly(this.computer, this.shipDefinitions)
    enddef

    def PlacePlayerShip(): bool
        if this.currentShipIndex >= len(this.shipDefinitions)
            return false
        endif

        var shipDef = this.shipDefinitions[this.currentShipIndex]
        var pos = this.cursor.position
        var orientation = this.cursor.orientation

        if this.player.board.CanPlaceShip(pos.row, pos.col, shipDef.size, orientation)
            var ship = ShipMod.Ship.new(shipDef)
            this.player.board.PlaceShip(ship, pos.row, pos.col, orientation)
            this.player.AddShip(ship)

            this.currentShipIndex += 1

            if this.currentShipIndex >= len(this.shipDefinitions)
                this.phase = C.GamePhase.BATTLE
                this.message = 'Battle! Use h,j,k,l to aim, Enter or s to shoot'
            else
                var nextShip = this.shipDefinitions[this.currentShipIndex]
                this.message = printf('Place your %s (%d cells). Use h,j,k,l to move, r to rotate, Enter or s to place',
                                     nextShip.name, nextShip.size)
            endif
            return true
        else
            this.message = 'Invalid placement! Try another position.'
            return false
        endif
    enddef

    def PlayerShoot(): string
        var pos = this.cursor.position

        if this.player.HasAlreadyShot(pos)
            this.message = 'Already shot here! Choose another target.'
            return this.message
        endif

        var isHit = this.computer.ReceiveShot(pos)
        this.player.RecordShot(pos, isHit)
        this.playerLastShotWasHit = isHit
        if isHit && this.variant == C.GameVariation.HIT_BONUS
            this.playerHitsThisTurn += 1
        endif
        this.playerShotsUsed += 1

        var resultMsg = ''
        if isHit
            var sunkShip = this.computer.GetSunkShip(pos)
            if sunkShip != null_object
                resultMsg = printf('You sank the computer''s %s!', sunkShip.definition.name)
            else
                resultMsg = 'Hit!'
            endif
        else
            resultMsg = 'Miss!'
        endif

        # Check win condition
        if this.computer.AllShipsSunk()
            this.phase = C.GamePhase.GAMEOVER
            this.message = 'YOU WIN! Press n for new game'
            return this.message
        endif

        # Determine shots allowed based on variant and current turn state
        var shotsAllowed = this.GetPlayerShotsAllowed()

        if this.playerShotsUsed < shotsAllowed
            this.message = printf('%s (%d/%d shots used). Choose next target or press ESC to end turn.',
                                 resultMsg, this.playerShotsUsed, shotsAllowed)
        else
            this.message = printf('%s Turn ends after %d shots.', resultMsg, shotsAllowed)
            # Computer's turn
            this.playerShotsUsed = 0
            this.playerLastShotWasHit = false
            this.playerHitsThisTurn = 0
            this.ComputerShoot()

            # Check lose condition
            if this.player.AllShipsSunk()
                this.phase = C.GamePhase.GAMEOVER
                this.message = 'Computer wins! Press n for new game'
            endif
        endif

        return this.message
    enddef

    def EndPlayerTurn()
        if this.playerShotsUsed > 0
            this.playerShotsUsed = 0
            this.playerLastShotWasHit = false
            this.playerHitsThisTurn = 0
            this.ComputerShoot()

            # Check lose condition
            if this.player.AllShipsSunk()
                this.phase = C.GamePhase.GAMEOVER
                this.message = 'Computer wins! Press n for new game'
            else
                this.message = 'Your turn ended. Choose a target.'
            endif
        endif
    enddef

    def ComputerShoot()
        var computerMsg = ''
        this.computerShotsUsed = 0
        this.computerLastShotWasHit = false
        this.computerHitsThisTurn = 0
        var shotIndex = 0
        var maxIterations = 10

        while shotIndex < maxIterations
            if !this.computer.HasAnyUnshot()
                break
            endif
            var shotsAllowed = this.GetComputerShotsAllowed()
            if this.computerShotsUsed >= shotsAllowed
                break  # Reached maximum shots for this turn
            endif

            var pos = this.playerLevel == C.PlayerLevel.EXPERT
                ? this.ai.ChooseSmartShot(this.computer, this.player)
                : this.ai.ChooseRandomShot(this.computer)
            var isHit = this.player.ReceiveShot(pos)
            this.computer.RecordShot(pos, isHit)
            this.computerLastShotWasHit = isHit
            if isHit && this.variant == C.GameVariation.HIT_BONUS
                this.computerHitsThisTurn += 1
            endif
            this.computerShotsUsed += 1
            shotIndex += 1

            if isHit
                var sunkShip = this.player.GetSunkShip(pos)
                if sunkShip != null_object
                    computerMsg ..= printf(' | Computer sank your %s!', sunkShip.definition.name)
                else
                    computerMsg ..= ' | Computer hit!'
                endif
            else
                computerMsg ..= ' | Computer missed'
                if this.variant != C.GameVariation.SHIP_COUNT
                    break  # Stop shooting on miss for HIT_BONUS and ONE_SHOT variants
                endif
            endif
        endwhile

        this.message = this.message .. computerMsg
    enddef

    def GetCurrentShipDef(): SD.ShipDefinition
        if this.currentShipIndex < len(this.shipDefinitions)
            return this.shipDefinitions[this.currentShipIndex]
        endif
        return null_object
    enddef

    def SelectVariant()
        this.selectedVariantIndex = (this.selectedVariantIndex + 1) % len(C.VARIANT_OPTIONS)
        this.UpdateVariantMessage()
    enddef

    def PreviousVariant()
        this.selectedVariantIndex = (this.selectedVariantIndex - 1 + len(C.VARIANT_OPTIONS)) % len(C.VARIANT_OPTIONS)
        this.UpdateVariantMessage()
    enddef

    def ConfirmVariant()
        this.variant = C.VARIANT_ENUMS[this.selectedVariantIndex]
        this.phase = C.GamePhase.PLACEMENT
        this.message = 'Place your Carrier (5 cells). Use h,j,k,l to move, r to rotate, Enter or s to place'
    enddef

    def UpdateVariantMessage()
        var option = C.VARIANT_OPTIONS[this.selectedVariantIndex]
        this.message = 'SELECT VARIANT: ' .. option[0] .. ': ' .. option[1] .. ' | j=next, k=prev, Enter/s=confirm'
    enddef

    def SelectLevel()
        this.selectedLevelIndex = (this.selectedLevelIndex + 1) % len(C.LEVEL_OPTIONS)
        this.UpdateLevelMessage()
    enddef

    def PreviousLevel()
        this.selectedLevelIndex = (this.selectedLevelIndex - 1 + len(C.LEVEL_OPTIONS)) % len(C.LEVEL_OPTIONS)
        this.UpdateLevelMessage()
    enddef

    def ConfirmLevel()
        this.playerLevel = C.LEVEL_ENUMS[this.selectedLevelIndex]
        this.phase = C.GamePhase.VARIANT_SELECTION
        this.UpdateVariantMessage()
    enddef

    def UpdateLevelMessage()
        var option = C.LEVEL_OPTIONS[this.selectedLevelIndex]
        this.message = 'SELECT LEVEL: ' .. option[0] .. ': ' .. option[1] .. ' | j=next, k=prev, Enter/s=confirm'
    enddef

    def GetLevelOption(): C.LevelOption
        var idx = index(C.LEVEL_ENUMS, this.playerLevel)
        if idx < 0
            return C.LEVEL_OPTIONS[0]
        endif
        return C.LEVEL_OPTIONS[idx]
    enddef

    def GetVariantOption(): C.VariantOption
        var idx = index(C.VARIANT_ENUMS, this.variant)
        if idx < 0
            return C.VARIANT_OPTIONS[0]
        endif
        return C.VARIANT_OPTIONS[idx]
    enddef

    def GetPlayerShotsAllowed(): number
        if this.variant == C.GameVariation.ONE_SHOT
            return 1
        elseif this.variant == C.GameVariation.HIT_BONUS
            return 1 + this.playerHitsThisTurn
        else
            var unsunkCount = Helpers.CountIf(this.computer.ships, (ship) => !ship.IsSunk())
            return unsunkCount > 0 ? unsunkCount : 1
        endif
    enddef

    def GetComputerShotsAllowed(): number
        if this.variant == C.GameVariation.ONE_SHOT
            return 1
        elseif this.variant == C.GameVariation.HIT_BONUS
            return 1 + this.computerHitsThisTurn
        else
            var unsunkCount = Helpers.CountIf(this.player.ships, (ship) => !ship.IsSunk())
            return unsunkCount > 0 ? unsunkCount : 1
        endif
    enddef
endclass
