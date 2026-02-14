# Battleship

A classic naval combat game playable directly within Vim. Challenge the computer to a tactical battle and attempt to sink all of its ships before it sinks all of yours.

## Features

- **Multiple Difficulty Levels**: Play against NOVICE (random) or EXPERT (probability-based) AI opponents
- **Game Variants**: 
  - **ONE SHOT**: Get one shot per turn
  - **HIT BONUS**: Get a bonus shot for each hit (unlimited bonus shots)
  - **SHIP COUNT**: Get shots equal to the number of unsunk enemy ships
- **5 Unique Ships**: Carrier (5), Battleship (4), Cruiser (3), Submarine (3), Destroyer (2)
- **Interactive Placement**: Visually place your ships on the board before battle
- **Strategic Gameplay**: Outthink the computer's AI to win
- **Full Vim Integration**: Buffer-local key bindings for seamless gameplay

## Installation

### Using a Vim Plugin Manager

#### vim-plug
Add this line to your `~/.vimrc`:

```vim
Plug 'yegappan/battleship'
```

Then run `:PlugInstall` in Vim.

### Manual Installation

1. Clone the repository:
```bash
git clone https://github.com/yegappan/battleship.git ~/.vim/pack/downloads/opt/battleship
```

2. Add the following line to your .vimrc file:
```vim
packadd battleship
```

3. Update Vim's help tags (optional but recommended):
```vim
:helptags ~/.vim/pack/downloads/opt/battleship/doc
```

## Getting Started

### Starting the Game

Use one of these commands in Vim:

```vim
:Battleship
:BattleshipNew
```

Both commands launch a new game in a new buffer.

### Game Flow

1. **Difficulty Selection**: Choose between NOVICE and EXPERT levels using `j`/`k` and press `Enter` or `s` to confirm
2. **Variant Selection**: Select your preferred game variant (ONE SHOT, HIT BONUS, or SHIP COUNT)
3. **Ship Placement**: Position all 5 ships on your board
4. **Battle**: Fire at the enemy board and defend against their attacks
5. **Gameover**: Win or lose, then start a new game or quit

## How to Play

### Key Bindings

#### Movement & Navigation
| Key | Action |
|-----|--------|
| Arrow Keys | Move up/down/left/right / Select in menus |
| `k` or `↑` | Move up / Select previous (in menus) |
| `j` or `↓` | Move down / Select next (in menus) |
| `h` or `←` | Move left |
| `l` or `→` | Move right |
| `H` | Jump to first row of current column |
| `L` | Jump to last row of current column |
| `Home` or `0` | Jump to first column of current row |
| `End` or `$` | Jump to last column of current row |
| `PageUp` | Jump to first row of current column |
| `PageDown` | Jump to last row of current column |

#### Actions
| Key | Action |
|-----|--------|
| `Enter` or `s` | Place ship (placement phase) or shoot target (battle phase) |
| `r` | Rotate ship between horizontal and vertical (placement phase) |
| `ESC` | End your turn during battle |

#### Game Control
| Key | Action |
|-----|--------|
| `n` | Start a new game |
| `q` | Quit game and close buffer |

### Game Phases

#### Level Selection
Navigate between NOVICE and EXPERT difficulty levels. NOVICE provides random AI shooting, while EXPERT uses probability-based targeting for a more challenging game.

#### Variant Selection
Choose your preferred game rules before battle starts. Each variant affects how many shots you get per turn.

#### Placement Phase
Position all 5 ships on your board:
- Use arrow keys or hjkl to move the ship preview
- Press `r` to rotate between horizontal and vertical
- Press `Enter` or `s` to place and move to the next ship
- Use `Home`/`End`/`PageUp`/`PageDown` (or `0`/`$`/`H`/`L`) for quick navigation to board edges

#### Battle Phase
Take turns firing at the opponent's board:
- Use arrow keys or hjkl to aim at enemy positions
- Press `Enter` or `s` to fire at the selected cell
- Use `Home`/`End`/`PageUp`/`PageDown` (or `0`/`$`/`H`/`L`) for quick navigation to board edges
- When you hit, you may get bonus shots depending on the variant
- The computer then takes its turn based on the selected difficulty and variant
- Battle continues until one side's ships are all sunk

#### Gameover
When the game ends:
- View the final game state
- Press `n` to play again with a new setup
- Press `q` to quit and return to normal Vim editing

## Game Rules

### Winning Conditions
- **You Win**: Sink all 5 computer ships before yours are all sunk
- **Computer Wins**: Sink all 5 of your ships before you sink theirs
- **Tie**: Impossible in standard Battleship rules

### Ship Placement
- Each ship must be placed horizontally or vertically (no diagonal placement)
- Ships cannot overlap
- Ships cannot be placed outside the board boundaries
- All ships must be placed before battle begins

### Combat
- Each shot targets one cell on the opponent's board
- Valid shots: empty water, unshot areas, or previous misses
- Hitting a ship marks that cell as a hit; other cells are misses
- When all cells of a ship are hit, the ship is sunk
- The number of shots per turn depends on your selected game variant

## Game Variants Explained

### ONE SHOT
- You get exactly one shot per turn
- Computer gets exactly one shot per turn
- Classic, methodical gameplay

### HIT BONUS
- You get a bonus shot for each hit (1 shot + 1 for each hit in your turn)
- Multiple consecutive hits can give you many shots in one turn
- Computer gets the same advantage
- Rewards aggressive targeting and can create powerful momentum swings

### SHIP COUNT
- You get shots equal to the number of unsunk enemy ships (1-5 shots per turn)
- Computer gets the same advantage
- Creates dynamic, escalating turns as ships are sunk

## Requirements

- Vim 9.0+ (uses Vim9script)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Enjoy!

Have fun playing Battleship in Vim! May your shots be accurate and your AI opponent's shots be inaccurate. ⚓
