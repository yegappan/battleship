vim9script

# ============================================================================
# FILE: autoload/battleship/computer_ai.vim
# PURPOSE: Implements intelligent AI targeting strategies for the computer opponent.
# CONTENTS:
#   - ComputerAI class: Implements IComputerAI interface with multiple shooting strategies
# KEY ALGORITHMS:
#   - ChooseRandomShot: Selects uniformly random unshot position
#   - ChooseSmartShot: Advanced targeting with hit-following and probability analysis
#     * Detects consecutive hits (ship lines) horizontally and vertically
#     * Targets ends of ship lines to maximize hits
#     * Uses parity-based search (even/odd checkerboard) when no hits found
#     * Scoreboard-based weighted selection: calculates possible ship placements
#   - ChooseWeighted: Weighted random selection using score distribution
#   - PlaceShipsRandomly: Random ship placement with collision checking
# KEY STRUCTURES:
#   - scores (2D array): Probability grid for ship placement likelihood
#   - lineCandidates: Adjacent positions to detected ship lines
#   - targetCandidates: Adjacent positions to isolated hits
# ============================================================================

import './constants.vim' as C
import './helpers.vim' as Helpers
import './icomputer_ai.vim' as IAI
import './player.vim' as PlayerMod
import './position.vim' as Pos
import './ship_definition.vim' as SD
import './ship.vim' as ShipMod

# CLASS: ComputerAI
# PURPOSE: Implements intelligent AI strategies for opponent targeting and ship placement
# IMPLEMENTS: IComputerAI interface
# KEY ALGORITHMS:
#   - ChooseRandomShot(): Uniformly random selection from unshot positions
#   - ChooseSmartShot(): Advanced targeting strategy with multiple phases:
#     * Phase 1: If hits exist, find and extend ship lines horizontally/vertically
#     * Phase 2: Target adjacent cells to isolated hits
#     * Phase 3: Generate probability grid by simulating all possible ship placements
#     * Phase 4: Use checkboard parity search to optimize coverage
#   - ChooseWeighted(): Weighted random selection based on score distribution
#   - PlaceShipsRandomly(): Random placement with collision detection
# KEY STRUCTURES:
#   - scores (2D array): Probability grid for ship placement likelihood
#   - lineCandidates: Positions adjacent to detected ship lines
#   - targetCandidates: Positions adjacent to isolated hits
export class ComputerAI implements IAI.IComputerAI
    def ChooseRandomShot(player: PlayerMod.Player): Pos.Position
        var available = Helpers.GetUnshotPositions(player)
        if len(available) == 0
            return Pos.Position.new(0, 0)
        endif
        return available[rand() % len(available)]
    enddef

    def ChooseWeighted(positions: Pos.PositionList, scores: list<list<number>>): Pos.Position
        var total = 0
        for pos in positions
            total += scores[pos.row][pos.col]
        endfor

        if total <= 0
            return positions[rand() % len(positions)]
        endif

        var target = rand() % total
        var cumulative = 0
        for pos in positions
            cumulative += scores[pos.row][pos.col]
            if cumulative > target
                return pos
            endif
        endfor

        return positions[len(positions) - 1]
    enddef

    def ChooseSmartShot(shooter: PlayerMod.Player, target: PlayerMod.Player): Pos.Position
        var hitPositions: Pos.PositionList = []
        for row in range(C.BOARD_SIZE)
            for col in range(C.BOARD_SIZE)
                if shooter.shotBoard.GetCell(row, col) == C.CELL_HIT
                    add(hitPositions, Pos.Position.new(row, col))
                endif
            endfor
        endfor

        if len(hitPositions) > 0
            var lineCandidates: Pos.PositionList = []
            var targetCandidates: Pos.PositionList = []
            var hasLineHit = false

            for hit in hitPositions
                var r = hit.row
                var c = hit.col

                if c + 1 < C.BOARD_SIZE && shooter.shotBoard.GetCell(r, c + 1) == C.CELL_HIT
                    hasLineHit = true
                    var left = c
                    while left - 1 >= 0 && shooter.shotBoard.GetCell(r, left - 1) == C.CELL_HIT
                        left -= 1
                    endwhile
                    var right = c + 1
                    while right + 1 < C.BOARD_SIZE && shooter.shotBoard.GetCell(r, right + 1) == C.CELL_HIT
                        right += 1
                    endwhile
                    if left - 1 >= 0 && shooter.shotBoard.GetCell(r, left - 1) == C.CELL_WATER
                        add(lineCandidates, Pos.Position.new(r, left - 1))
                    endif
                    if right + 1 < C.BOARD_SIZE && shooter.shotBoard.GetCell(r, right + 1) == C.CELL_WATER
                        add(lineCandidates, Pos.Position.new(r, right + 1))
                    endif
                endif

                if r + 1 < C.BOARD_SIZE && shooter.shotBoard.GetCell(r + 1, c) == C.CELL_HIT
                    hasLineHit = true
                    var top = r
                    while top - 1 >= 0 && shooter.shotBoard.GetCell(top - 1, c) == C.CELL_HIT
                        top -= 1
                    endwhile
                    var bottom = r + 1
                    while bottom + 1 < C.BOARD_SIZE && shooter.shotBoard.GetCell(bottom + 1, c) == C.CELL_HIT
                        bottom += 1
                    endwhile
                    if top - 1 >= 0 && shooter.shotBoard.GetCell(top - 1, c) == C.CELL_WATER
                        add(lineCandidates, Pos.Position.new(top - 1, c))
                    endif
                    if bottom + 1 < C.BOARD_SIZE && shooter.shotBoard.GetCell(bottom + 1, c) == C.CELL_WATER
                        add(lineCandidates, Pos.Position.new(bottom + 1, c))
                    endif
                endif

                if r - 1 >= 0 && shooter.shotBoard.GetCell(r - 1, c) == C.CELL_WATER
                    add(targetCandidates, Pos.Position.new(r - 1, c))
                endif
                if r + 1 < C.BOARD_SIZE && shooter.shotBoard.GetCell(r + 1, c) == C.CELL_WATER
                    add(targetCandidates, Pos.Position.new(r + 1, c))
                endif
                if c - 1 >= 0 && shooter.shotBoard.GetCell(r, c - 1) == C.CELL_WATER
                    add(targetCandidates, Pos.Position.new(r, c - 1))
                endif
                if c + 1 < C.BOARD_SIZE && shooter.shotBoard.GetCell(r, c + 1) == C.CELL_WATER
                    add(targetCandidates, Pos.Position.new(r, c + 1))
                endif
            endfor

            if len(lineCandidates) > 0
                return lineCandidates[rand() % len(lineCandidates)]
            endif
            if !hasLineHit && len(targetCandidates) > 0
                return targetCandidates[rand() % len(targetCandidates)]
            endif
        endif

        var remainingSizes: list<number> = []
        for ship in target.ships
            if !ship.IsSunk()
                add(remainingSizes, ship.definition.size)
            endif
        endfor

        if len(remainingSizes) == 0
            return this.ChooseRandomShot(shooter)
        endif

        var scores: list<list<number>> = []
        var hasAnyHit = false
        for row in range(C.BOARD_SIZE)
            var scoreRow: list<number> = []
            for col in range(C.BOARD_SIZE)
                add(scoreRow, 0)
                if shooter.shotBoard.GetCell(row, col) == C.CELL_HIT
                    hasAnyHit = true
                endif
            endfor
            add(scores, scoreRow)
        endfor

        for size in remainingSizes
            for row in range(C.BOARD_SIZE)
                for col in range(C.BOARD_SIZE)
                    if col + size <= C.BOARD_SIZE
                        var valid = true
                        var hasHitInPlacement = false
                        for i in range(size)
                            var cell = shooter.shotBoard.GetCell(row, col + i)
                            if cell == C.CELL_MISS
                                valid = false
                                break
                            endif
                            if cell == C.CELL_HIT
                                hasHitInPlacement = true
                            endif
                        endfor
                        if valid && (!hasAnyHit || hasHitInPlacement)
                            for i in range(size)
                                if shooter.shotBoard.GetCell(row, col + i) == C.CELL_WATER
                                    scores[row][col + i] += 1
                                endif
                            endfor
                        endif
                    endif

                    if row + size <= C.BOARD_SIZE
                        var validV = true
                        var hasHitInPlacementV = false
                        for i in range(size)
                            var cellV = shooter.shotBoard.GetCell(row + i, col)
                            if cellV == C.CELL_MISS
                                validV = false
                                break
                            endif
                            if cellV == C.CELL_HIT
                                hasHitInPlacementV = true
                            endif
                        endfor
                        if validV && (!hasAnyHit || hasHitInPlacementV)
                            for i in range(size)
                                if shooter.shotBoard.GetCell(row + i, col) == C.CELL_WATER
                                    scores[row + i][col] += 1
                                endif
                            endfor
                        endif
                    endif
                endfor
            endfor
        endfor

        var bestPositions: Pos.PositionList = []
        var parityPositions: Pos.PositionList = []
        var bestScore = -1
        for row in range(C.BOARD_SIZE)
            for col in range(C.BOARD_SIZE)
                if shooter.shotBoard.GetCell(row, col) != C.CELL_WATER
                    continue
                endif
                if (row + col) % 2 == 0
                    add(parityPositions, Pos.Position.new(row, col))
                endif
                var score = scores[row][col]
                if score > bestScore
                    bestScore = score
                    bestPositions = [Pos.Position.new(row, col)]
                elseif score == bestScore
                    add(bestPositions, Pos.Position.new(row, col))
                endif
            endfor
        endfor

        if len(parityPositions) > 0
            return this.ChooseWeighted(parityPositions, scores)
        endif

        if len(bestPositions) == 0
            return this.ChooseRandomShot(shooter)
        endif

        return this.ChooseWeighted(bestPositions, scores)
    enddef

    def PlaceShipsRandomly(player: PlayerMod.Player, shipDefinitions: SD.ShipDefinitions)
        for shipDef in shipDefinitions
            var placed = false
            while !placed
                var row = rand() % C.BOARD_SIZE
                var col = rand() % C.BOARD_SIZE
                var orientation = (rand() % 2) == 0 ? C.Orientation.HORIZONTAL : C.Orientation.VERTICAL

                if player.board.CanPlaceShip(row, col, shipDef.size, orientation)
                    var ship = ShipMod.Ship.new(shipDef)
                    player.board.PlaceShip(ship, row, col, orientation)
                    player.AddShip(ship)
                    placed = true
                endif
            endwhile
        endfor
    enddef
endclass
