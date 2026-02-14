vim9script

# ============================================================================
# FILE: autoload/battleship/constants.vim
# PURPOSE: Defines immutable constants, enumerations, and configuration for the game.
# CONTENTS:
#   - Board configuration: Size (10x10) and cell symbols
#   - Ship definitions: Symbols for each ship type
#   - Game phase enum: LEVEL_SELECTION, VARIANT_SELECTION, PLACEMENT, BATTLE, GAMEOVER
#   - Game variation options: ONE_SHOT, HIT_BONUS, SHIP_COUNT
#   - Player level options: NOVICE, EXPERT
#   - Ship types: CARRIER, BATTLESHIP, CRUISER, SUBMARINE, DESTROYER
#   - Orientation: HORIZONTAL, VERTICAL
# KEY SYMBOLS:
#   - ≈ (water), ◦ (empty), ✓ (hit), ◇ (miss), ★ (preview), ◉ (cursor)
# ============================================================================

export const BOARD_SIZE = 10
export const TOTAL_SHIP_CELLS = 17

export const CELL_WATER = '≈'
export const CELL_EMPTY = '◦'
export const CELL_HIT = '✓'
export const CELL_MISS = '◇'
export const CELL_PREVIEW = '★'
export const CELL_CURSOR = '◉'

export const SHIP_CARRIER = 'C'
export const SHIP_BATTLESHIP = 'B'
export const SHIP_CRUISER = 'R'
export const SHIP_SUBMARINE = 'S'
export const SHIP_DESTROYER = 'D'

export type VariantOption = tuple<string, string>
export type LevelOption = tuple<string, string>

export const VARIANT_OPTIONS: list<VariantOption> = [
    ('ONE SHOT', 'One shot per turn'),
    ('HIT BONUS', 'Bonus shot for each hit'),
    ('SHIP COUNT', 'Shots equal unsunk enemy ships')
]

export const LEVEL_OPTIONS: list<LevelOption> = [
    ('NOVICE', 'Computer shoots randomly'),
    ('EXPERT', 'Computer uses probability targeting')
]

export enum GamePhase
    LEVEL_SELECTION,
    VARIANT_SELECTION,
    PLACEMENT,
    BATTLE,
    GAMEOVER
endenum

export enum GameVariation
    ONE_SHOT,
    HIT_BONUS,
    SHIP_COUNT
endenum

export enum PlayerLevel
    NOVICE,
    EXPERT
endenum

export const VARIANT_ENUMS: list<GameVariation> = [
    GameVariation.ONE_SHOT,
    GameVariation.HIT_BONUS,
    GameVariation.SHIP_COUNT
]

export const LEVEL_ENUMS: list<PlayerLevel> = [
    PlayerLevel.NOVICE,
    PlayerLevel.EXPERT
]

export enum ShipType
    CARRIER,
    BATTLESHIP,
    CRUISER,
    SUBMARINE,
    DESTROYER
endenum

export enum Orientation
    HORIZONTAL,
    VERTICAL
endenum
