# Battleship Game in Vim9script

A classic naval combat game playable directly within Vim. Challenge the computer to a tactical battle and attempt to sink all of its ships before it sinks all of yours. Written entirely in Vim9script to showcase modern language features.

## Features

- **Multiple Difficulty Levels**: Play against NOVICE (random) or EXPERT (probability-based) AI
- **Game Variants**: Choose between ONE SHOT, HIT BONUS, or SHIP COUNT gameplay
- **5 Ships**: Carrier (5), Battleship (4), Cruiser (3), Submarine (3), Destroyer (2)
- **Interactive Placement**: Visually place your ships before battle
- **Strategic AI**: Challenge the computer's tactical decision-making
- **Full Vim Integration**: Seamless gameplay with buffer-local key bindings
- **Modern Vim9script Design**: Demonstrates classes, interfaces, and type safety

## Requirements

- Vim 9.0 or later with Vim9script support
- **NOT compatible with Neovim** (requires Vim9-specific features)

## Installation

### Using Git
If you have git installed, run the following command in your terminal:

**Unix/Linux/macOS:**

```bash
git clone https://github.com/yegappan/battleship.git ~/.vim/pack/downloads/opt/battleship
```
**Windows (cmd.exe):**

```cmd
git clone https://github.com/yegappan/battleship.git %USERPROFILE%\vimfiles\pack\downloads\opt\battleship
```

### Using a ZIP file
If you prefer not to use Git:

**Unix/Linux/macOS:**

Create the destination directory:

```bash
mkdir -p ~/.vim/pack/downloads/opt/
```

Download the plugin ZIP file from GitHub and extract its contents into the directory created above.

*Note:* GitHub usually names the extracted folder battleship-main. Rename it to battleship so the final path looks like this:

```plaintext
~/.vim/pack/downloads/opt/battleship/
├── plugin/
├── autoload/
└── doc/
```

**Windows (cmd.exe):**

Create the destination directory:

```cmd
if not exist "%USERPROFILE%\vimfiles\pack\downloads\opt" mkdir "%USERPROFILE%\vimfiles\pack\downloads\opt"
```

Download the plugin ZIP file from GitHub and extract its contents into that directory.

*Note:* Rename the extracted folder (usually battleship-main) to battleship so the path matches:

```plaintext
%USERPROFILE%\vimfiles\pack\downloads\opt\battleship\
├── plugin/
├── autoload/
└── doc/
```

**Finalizing Setup**
Since this plugin is installed in the opt (optional) directory, it will not load automatically. Add the following line to your .vimrc (Unix) or _vimrc (Windows):

```viml
packadd battleship
```

After adding the line, restart Vim and run the following command to enable the help documentation:

```viml
:helptags ALL
```

### Plugin Manager Installation

If using a plugin manager like vim-plug, add to your .vimrc or init.vim:

   ```viml
   Plug 'path/to/battleship'
   ```

Then run `:PlugInstall` and `:helptags ALL`

For other plugin managers (Vundle, Pathogen, etc.), follow their standard
installation procedures for local plugins.

## Usage

### Starting the Game

```vim
:Battleship
```

### Controls

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

### Game Flow & Phases

1. **Difficulty Selection**: Choose between NOVICE and EXPERT levels using `j`/`k` and press `Enter` or `s` to confirm. NOVICE uses random AI, EXPERT uses probability-based targeting
2. **Variant Selection**: Select your preferred game variant (ONE SHOT, HIT BONUS, or SHIP COUNT)
3. **Ship Placement**: Position all 5 ships on your board (Carrier 5, Battleship 4, Cruiser 3, Submarine 3, Destroyer 2)
4. **Battle**: Fire at the enemy board and defend against their attacks
5. **Gameover**: Win or lose, then start a new game or quit

### Game Rules

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

## Game Variants

### ONE SHOT
- Exactly one shot per turn for both player and computer
- Classic, methodical gameplay

### HIT BONUS
- Get a bonus shot for each hit
- Multiple consecutive hits create momentum
- Computer gets the same advantage

### SHIP COUNT
- Get shots equal to the number of unsunk enemy ships (1-5 per turn)
- Creates dynamic, escalating gameplay
- Computer gets the same advantage

## License

This plugin is licensed under the MIT License. See the LICENSE file in the repository for details.
