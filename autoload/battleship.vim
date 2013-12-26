" Battleship Game for Vim
" Author: Yegappan Lakshmanan
" Version: 1.0
" Last Modified: 15th March 2008
"

if v:version < 700
    " Vim7 is required for this plugin
    finish
endif

" Use Vim default 'cpo' setting
let s:cpo_save = &cpo
set cpo&vim

let s:ship_names = ['Carrier', 'Battleship', 'Cruiser', 'PatrolBoat',
	    \ 'Submarine']

" Three game types are supported
" Type 1 - One shot per turn
" Type 2 - One shot per turn and additional shots if the previous shot is a
"          hit
" Type 3 - Number of shots depends on the number of ships not yet found by
"          the opponent. On game start, five shots per turn.
let s:game_type=1

" Warn_msg {{{1
function! s:Warn_msg(msg)
    echohl WarningMsg
    echomsg a:msg
    echohl None
endfunction

" Trace {{{1
function! s:Trace(msg)
    "redir >> /users/yega/battleship.trace
    "silent echo a:msg
    "redir END
endfunction

"-----------------
" Cell dictionary {{{1
"-----------------
let s:cell = {
	    \ 'grid' : {},
	    \ 'row' : 0,
	    \ 'column' : 0,
	    \ 'ship' : {'size':0},
	    \ 'open' : 0
	    \ }

" cell.new
" Create a new cell instance
function! s:cell.new(grid, r, c) dict
    let new_cell = deepcopy(self)

    let new_cell.grid = a:grid
    let new_cell.row = a:r
    let new_cell.column = a:c

    " User cannot create new cells with the new cell instance
    unlet new_cell.new

    return new_cell
endfunction

function! s:cell.SetCellChar(ch) dict
    if self.row == 0 || self.column == 0
        return
    endif

    call self.grid.PlaceCursorOnCell(self)

    let save_ma = &l:modifiable
    setlocal modifiable
    exe "normal! r" . a:ch
    let &l:modifiable = save_ma
endfunction

" cell.Open
" This cell is opened
function! s:cell.Open() dict
    let self.open = 1

    call self.SetCellChar('!')
    redraw!
    sleep 1

    if self.IsOccupied()
        call self.grid.ShowStatus('HIT')
	call self.SetCellChar('X')

	call self.ship.UpdateHit()
    else
        call self.grid.ShowStatus('MISS')
	call self.SetCellChar('O')
    endif
endfunction

" cell.IsOpen
" Is this cell opened?
function! s:cell.IsOpen() dict
    return self.open
endfunction

" cell.IsHit
" Is this cell opened and is hit?
function! s:cell.IsHit() dict
    return self.open && self.ship.size != 0
endfunction

" cell.IsOccupied
" Is this cell occupied
function! s:cell.IsOccupied() dict
    return self.ship.size != 0
endfunction

" cell.RemoveShip
" Remove a ship from the current cell
function! s:cell.RemoveShip() dict
    let self.ship = {'size' : 0}
    call self.SetCellChar(' ')
endfunction

" cell.GetPos
" Return the cell position (row, column) in the grid
function! s:cell.GetPos() dict
    return [self.row, self.column]
endfunction

" The Cell dictionary cannot be modified
lockvar s:cell

"-----------------
" Ship dictionary {{{1
"-----------------
let s:ship = {
	    \ 'name' : '',
	    \ 'grid' : {},
	    \ 'size' : 0,
	    \ 'cells' : [{}],
	    \ 'sunk' : 0
	    \ }

" ship.new
" Create a new ship instance
function! s:ship.new(grid, name, sz) dict
    let new_ship = deepcopy(self)

    let new_ship.name = a:name
    let new_ship.grid = a:grid
    let new_ship.size = a:sz

    " User cannot create new ships with the new ship instance
    unlet new_ship.new

    return new_ship
endfunction

" ship.GetHitCount
" Get the number of cells hit in this ship
function! s:ship.GetHitCount() dict
    let hit_cnt = 0
    for i in range(1, self.size)
	let cell = self.cells[i]
	if cell.IsOpen()
	    let hit_cnt += 1
	endif
    endfor

    return hit_cnt
endfunction

" ship.UpdateHit
" Update the ship cell hit information
function! s:ship.UpdateHit() dict
    let hit_cnt = self.GetHitCount()
    if hit_cnt == self.size
        call self.grid.ShowStatus('SUNK')
	let self.sunk = 1
	for i in range(1, self.size)
	    call self.cells[i].SetCellChar('*')
	endfor
    endif
endfunction

" ship.TryPlaceShip
" Try placing the ship at the specified cell in the specified orientation
function! s:ship.TryPlaceShip(cell, orient) dict
    let [sr, sc] = a:cell.GetPos()

    for i in range(1, self.size)
	let cell = self.grid.GetCell(sr, sc)
	if cell.IsOccupied()
	    return 0
	endif

	if a:orient == 1
	    let sc += 1
	else
	    let sr += 1
	endif

	if sr > 10 || sc > 10
	    return 0
	endif
    endfor

    let [sr, sc] = a:cell.GetPos()

    for i in range(1, self.size)
	let cell = self.grid.GetCell(sr, sc)
	let cell.ship = self

	call add(self.cells, cell)

	if a:orient == 1
	    let sc += 1
	else
	    let sr += 1
	endif
    endfor

    return 1
endfunction

" ship.PlaceShip
" Place the ship on the grid
function! s:ship.PlaceShip() dict
    while 1
	let cell = self.grid.FindRandomEmptyCell()
	let orient = Urndm(1, 2)

	if self.TryPlaceShip(cell, orient)
	    return
	endif
    endwhile
endfunction

" ship.GetSize
" Return the size of this ship
function! s:ship.GetSize() dict
    return self.size
endfunction

" ship.IsSunk
" Is this ship sunk
function! s:ship.IsSunk() dict
    return self.sunk
endfunction

" ship.Remove
" Remove the sip and clear the occupied cells
function! s:ship.Remove() dict
    for ship_cell in self.cells
        if empty(ship_cell)
            continue
        endif
        call ship_cell.RemoveShip()
    endfor

    let self.cells = {}
endfunction

" The Ship dictionary cannot be modified
lockvar s:ship

"
"-----------------
" Grid dictionary {{{1
"-----------------
let s:grid = {
	    \ 'top' : 0,
	    \ 'bottom' : 0,
	    \ 'left' : 0,
	    \ 'right' : 0,
	    \ 'cells' : [],
	    \ 'ships' : {},
	    \ 'num_shots' : 0,
            \ 'shots_per_turn' : 0,
            \ 'shots_remain' : 0
	    \ }

" grid.new
" Create a new grid dictionary
function! s:grid.new() dict                     "{{{2
    let new_grid = deepcopy(self)

    for r in range(0, 10)
	let r_cells = []
	for c in range(0, 10)
	    call add(r_cells, s:cell.new(new_grid, r, c))
	endfor
	call add(new_grid.cells, r_cells)
    endfor

    " User cannot create new grids with the new grid instance
    unlet new_grid.new

    return new_grid
endfunction

" grid.IsValidCellPos
" Checks whether the given row, col is a valid cell position
function! s:grid.IsValidCellPos(r, c)
    return a:r >= 1 && a:r <= 10 && a:c >= 1 && a:c <= 10
endfunction

" grid.GetCell
" Get the cell at the specified row/column.
" Returns empty dict if invalid position is specified
function! s:grid.GetCell(r, c) dict
    if !self.IsValidCellPos(a:r, a:c)
        return {}
    endif

    let r_cells = self.cells[a:r]
    return r_cells[a:c]
endfunction

" grid.PlaceCursorOnCell
" Place the cursor on the cell
function! s:grid.PlaceCursorOnCell(cell) dict
    let [r, c] = a:cell.GetPos()

    let lnum = ((r - 1) * 2) + self.top
    let col = ((c - 1) * 2) + self.left

    call cursor(lnum, col)
endfunction

" grid.GetCellUnderCursor
" Get the cell under the cursor
function! s:grid.GetCellUnderCursor() dict
    let cur_lnum = line('.')
    let cur_col = col('.')

    let r = (cur_lnum - self.top) / 2 + 1
    let c = (cur_col - self.left) / 2 + 1

    return self.GetCell(r, c)
endfunction

" grid.FindRandomEmptyCell
" Find a random empty (not yet used by a ship) cell
function! s:grid.FindRandomEmptyCell() dict
    let num_tries = 100
    while num_tries > 0
	let r = Urndm(1, 10)
	let c = Urndm(1, 10)
	let cell = self.GetCell(r, c)
	if !cell.IsOccupied()
	    return cell
	endif

        let num_tries -= 1
    endwhile

    return {}
endfunction

" grid.FindRandomClosedCell
" Find a random not yet open cell
function! s:grid.FindRandomClosedCell() dict
    let num_tries = 100
    while num_tries > 0
	let r = Urndm(1, 10)
	let c = Urndm(1, 10)
	let cell = self.GetCell(r, c)
	if !cell.IsOpen()
	    return cell
	endif
	let num_tries -= 1
    endwhile

    return {}
endfunction

" grid.GetNeighborCell
" Get the neighbor cell in the specified direction
function! s:grid.GetNeighborCell(cell, dir) dict
    let [r, c] = a:cell.GetPos()

    if a:dir == 'up'
        let r -= 1
    elseif a:dir == 'down'
        let r += 1
    elseif a:dir == 'left'
        let c -= 1
    elseif a:dir == 'right'
        let c += 1
    elseif a:dir == 'top'
	let r = 1
    elseif a:dir == 'bottom'
	let r = 10
    elseif a:dir == 'first'
	let c = 1
    elseif a:dir == 'last'
	let c = 10
    endif

    return self.GetCell(r, c)
endfunction

" grid.CountEmptyCellsInDir
" Count the number of empty cells in the given direction (including the
" specified cell)
" dir - Direction to check
" max_sz - Maximum number of cells to check
function! s:grid.CountEmptyCellsInDir(cell, dir, max_sz) dict
    let cell_cnt = 1  " Include the specified cell also
    let next_cell = a:cell

    while cell_cnt < a:max_sz
        let next_cell = self.GetNeighborCell(next_cell, a:dir)
        if empty(next_cell) || next_cell.IsOpen()
            " Reached the end of the grid or an opened cell
            break
        endif

        let cell_cnt += 1
    endwhile

    return cell_cnt
endfunction

" grid.GetFloatingShipsSizeRange
" Get the minimum and maximum size of the floating ships
function! s:grid.GetFloatingShipsSizeRange()
    let max_sz = 2
    let min_sz = 5

    let cnt = 0

    for ship in values(self.ships)
        if !ship.IsSunk()
            if ship.size > max_sz
                let max_sz = ship.size
            endif
            if ship.size < min_sz
                let min_sz = ship.size
            endif
            let cnt += 1
        endif
    endfor

    if cnt > 0
        return [min_sz, max_sz]
    else
        return [0, 0]
    endif
endfunction

" grid.CountPossibleShipsInCell
" Count the number of possible ships that can be placed in the specified cell
" in all the directions. The specified cell is assumed to be the starting
" cell for the ship
function! s:grid.CountPossibleShipsInCell(cell) dict
    let [min_sz, max_sz] = self.GetFloatingShipsSizeRange()

    let ship_cnt = {}
    for dir in ['right', 'up', 'left', 'down']
        let cell_cnt = self.CountEmptyCellsInDir(a:cell, dir, max_sz)
        let cnt = 0
        for ship in values(self.ships)
            if ship.IsSunk()
                " Ignore sunk ships
                continue
            endif
            if ship.size <= cell_cnt
                let cnt += 1
            endif
        endfor
        let ship_cnt[dir] = cnt
    endfor

    return ship_cnt
endfunction

" grid.ComputeDirForNextShot
" Compute the direction for the next shot. This is based on the number of
" free cells in that direction and the size of the ships not yet hit.
" min_sz - Minimum number of free cells
" max_sz - Maximum number of cells to check
function! s:grid.ComputeDirForNextShot(cell) dict
    let ship_cnt = self.CountPossibleShipsInCell(a:cell)

    let next_shot_dir = ''
    let max_ships = 0
    for dir in keys(ship_cnt)
        call s:Trace(printf("Number of ships in cell [%d,%d] in dir %s is %d", a:cell.row, a:cell.column, dir, ship_cnt[dir]))
        if ship_cnt[dir] > max_ships
            let max_ships = ship_cnt[dir]
            let next_shot_dir = dir
        endif
    endfor

    return next_shot_dir
endfunction

" grid.GetShip
" Return the ship with the specified name
function! s:grid.GetShip(name) dict
    return self.ships[a:name]
endfunction

" grid.GetNeighborClosedCellInDir
" Find a neighbor closed cell in the specified direction
function! s:grid.GetNeighborClosedCellInDir(cell, dir) dict
    let ncell = self.GetNeighborCell(a:cell, a:dir)
    if !empty(ncell) && !ncell.IsOpen()
        return ncell
    endif

    return {}
endfunction

" grid.FindNeighborClosedCell
" Find a not yet opened cell next to the specified cell in any direction
function! s:grid.FindNeighborClosedCell(cell) dict
    for dir in ['up', 'right', 'down', 'left']
        let ncell = self.GetNeighborClosedCellInDir(a:cell, dir)
        if !empty(ncell)
            return [ncell, dir]
        endif
    endfor

    " Couldn't find a closed neighbor cell
    return [{}, '']
endfunction

" grid.RemoveAllShips
" Remove all the ships from the grid
function! s:grid.RemoveAllShips() dict
    if empty(self.ships)
        return
    endif

    " Remove all the ship
    for ship in values(self.ships)
        call ship.Remove()
    endfor

    let self.ships = {}
endfunction

" grid.PlaceShips
" Place ships on the grid at random locations
function! s:grid.PlaceShips() dict
    call self.RemoveAllShips()

    let self.ships.Carrier = s:ship.new(self, 'Carrier', 5)
    let self.ships.Battleship = s:ship.new(self, 'Battleship', 4)
    let self.ships.Cruiser = s:ship.new(self, 'Cruiser', 3)
    let self.ships.PatrolBoat = s:ship.new(self, 'PatrolBoat', 2)
    let self.ships.Submarine = s:ship.new(self, 'Submarine', 3)

    call self.ships.Carrier.PlaceShip()
    call self.ships.Battleship.PlaceShip()
    call self.ships.Cruiser.PlaceShip()
    call self.ships.PatrolBoat.PlaceShip()
    call self.ships.Submarine.PlaceShip()
endfunction

" grid.CursorOnGrid
" Return 1 if the cursor is on the grid
function! s:grid.CursorOnGrid() dict
    let lnum = line('.')
    let col = col('.')

    if lnum % 2 || col % 2
	return 0
    endif

    if lnum >= self.top && lnum <= self.bottom &&
		\ col >= self.left && col <= self.right
	return 1
    else
	return 0
    endif
endfunction

" grid.GetFloatingShipsCount
" Get the number of ships floating (not sunk) in this grid
function! s:grid.GetFloatingShipsCount() dict
    let ships_floating = 0
    for ship in values(self.ships)
	if !ship.IsSunk()
            let ships_floating += 1
        endif
    endfor

    return ships_floating
endfunction

" grid.ShowFloatingShips
" Show ships that are not yet sunk
function! s:grid.ShowFloatingShips() dict
    for ship in values(self.ships)
	for ship_cell in ship.cells
	    if empty(ship_cell)
		continue
	    endif
            if ship_cell.IsOpen()
                continue
            endif
	    call ship_cell.SetCellChar('I')
	endfor
    endfor
endfunction

" grid.ShowStatus
function! s:grid.ShowStatus(status) dict
    let l = strlen(a:status)
    let msg = repeat(' ', self.right + 1 - l) . a:status
    setlocal modifiable
    call setline(self.bottom + 2, msg)
    redraw!
    sleep 1
    call setline(self.bottom + 2, '')
    setlocal nomodifiable
endfunction

lockvar s:grid

" GameCompleted: Game completed
function! s:GameCompleted(player_won)
    let s:game_over = 1

    setlocal modifiable

    call append('$', repeat(' ', 26) . '!!! Game Over !!!')
    syntax match Search '!!! Game Over !!!'

    call append('$', '')
    if a:player_won
        let str = repeat(' ', 27)
        let str = str . '--- You Win ---'
    else
        let str = repeat(' ', 24)
        let str = str . '--- Computer Wins ---'
    endif
    call append('$', str)

    if a:player_won == 0
        " When the computer wins, show the computer ships not found
        " by the user
        call s:user_grid.ShowFloatingShips()
    endif

    setlocal nomodifiable

    redraw

    " Check with the user whether he wants to play another game
    let ans = confirm("Do you want to play another game (Y/N)? ", "&Yes\n&No", "N")
    if ans == 2
        " Close the battleship buffer
        enew
    else
        " Start a new game
        call s:NewGame()
    endif
endfunction

" UpdateGameStatus {{{1
function! s:UpdateGameStatus()
    let save_pos = getpos('.')

    let s = []
    let user_ships_sunk = 0
    let comp_ships_sunk = 0

    let l = repeat(' ', 8) .
		\ printf("Total shots: %-2d", s:user_grid.num_shots)
    let l = l . repeat(' ', 15) .
		\ printf("Total shots: %-2d", s:comp_grid.num_shots)

    call add(s, l)

    for name in s:ship_names
	let l = repeat(' ', 8)

	let ship = s:user_grid.GetShip(name)
	let l = l . printf("%-11s: ", name)
	if ship.IsSunk()
	    let l = l . 'S    '
	    let comp_ships_sunk += 1
	else
	    let l = l . ship.GetSize()
	    let hit_cnt = ship.GetHitCount()
	    let l = l . ' [' . hit_cnt . ']'
	endif

	let ship = s:comp_grid.GetShip(name)
	let l = l . repeat(' ', 12) . printf("%-11s: ", name)
	if ship.IsSunk()
	    let l = l . 'S    '
	    let user_ships_sunk += 1
	else
	    let l = l . ship.GetSize()
	    let hit_cnt = ship.GetHitCount()
	    let l = l . ' [' . hit_cnt . ']'
	endif

	call add(s, l)
    endfor

    setlocal modifiable

    silent! 28,$delete _
    call append('$', '')

    let game_over = 0
    if user_ships_sunk == 5 || comp_ships_sunk == 5
        let game_over = 1
    endif

    if !game_over
	call append('$', s)
        setlocal nomodifiable
        call setpos('.', save_pos)
    else
        call s:GameCompleted(comp_ships_sunk == 5)
    endif
endfunction

" GetReverseDir {{{1
" Get the opposite direction for the specified dir
function! s:GetReverseDir(dir)
    if a:dir == 'up'
	return 'down'
    elseif a:dir == 'down'
	return 'up'
    elseif a:dir == 'right'
	return 'left'
    elseif a:dir == 'left'
	return 'right'
    endif
endfunction

" PickCell {{{1
" Choose a cell for the computer's turn
function! s:PickCell()
    if !empty(s:last_hit_cell) 
        " If the last shot hit a ship, then try hitting an empty cell
        " near that in the same direction
        call s:Trace(printf("Last hit cell [%d, %d], dir = %s",
                    \ s:last_hit_cell.row,
                    \ s:last_hit_cell.column, s:last_dir))
	let cell = s:comp_grid.GetNeighborClosedCellInDir(s:last_hit_cell,
                    \ s:last_dir)
        if !empty(cell)
            call s:Trace(printf("Found a closed cell at [%d, %d] in dir = %s",
                        \ cell.row, cell.column, s:last_dir))
            return cell
        endif

        call s:Trace("Not able to find a closed cell near last hit cell")

        " Not able to find an empty cell near the last hit cell
        " Try in the opposite direction from the first hit cell
        let s:last_dir = s:GetReverseDir(s:last_dir)

        call s:Trace(printf("Checking for closed cells near [%d, %d] in " .
                    \ "dir = %s", s:first_hit_cell.row,
                    \ s:first_hit_cell.column, s:last_dir))
        let cell = s:comp_grid.GetNeighborClosedCellInDir(s:first_hit_cell,
                    \ s:last_dir)
        if !empty(cell)
            call s:Trace(printf("Found a closed cell at [%d, %d] in " .
                        \ "dir = %s", cell.row, cell.column, s:last_dir))
            return cell
        endif

        call s:Trace("Not able to find a closed cell near first hit cell")

        " Not able to find a closed cell next to both the first and
        " last hit cells. Try to find a closed cell near the last
        " hit cell in any direction.
        call s:Trace(printf("Checking for closed cells near [%d, %d] in " .
                    \ "any direction", s:last_hit_cell.row,
                    \ s:last_hit_cell.column))
        let [cell, s:last_dir] = s:comp_grid.FindNeighborClosedCell(
                    \ s:last_hit_cell)

        if !empty(cell)
            call s:Trace(printf("Found a closed cell at [%d, %d] in dir = %s",
                        \ cell.row, cell.column, s:last_dir))
            return cell
        endif

        " Not able to find a closed cell next to the last hit cell.
        " Try to find a closed cell near the first hit cell in any
        " direction.
        call s:Trace(printf("Checking for closed cells near [%d, %d] in " .
                    \ "any direction", s:first_hit_cell.row,
                    \ s:first_hit_cell.column))
        let [cell, s:last_dir] = s:comp_grid.FindNeighborClosedCell(
                    \ s:first_hit_cell)

        if !empty(cell)
            call s:Trace(printf("Found a closed cell at [%d, %d] in dir = %s",
                        \ cell.row, cell.column, s:last_dir))
            return cell
        endif
    endif

    let cell = s:comp_grid.FindRandomClosedCell()

    if s:skill_level == 'Novice'
        return cell
    endif

    let s:last_dir = ''
    while !empty(cell)
        " Check whether there are enough cells nearby to fit a floating ship.
        " Otherwise pick another random cell.

        call s:Trace(printf("Computing next shot dir near [%d, %d]", cell.row, cell.column))

        let s:last_dir = s:comp_grid.ComputeDirForNextShot(cell)
        if s:last_dir != ''
            call s:Trace(printf("Next shot direction is %s", s:last_dir))
            break
        endif

        let cell = s:comp_grid.FindRandomClosedCell()
    endwhile

    return cell
endfunction

" ComputerFireOneShot {{{1
" Computer fires a shot
function! s:ComputerFireOneShot()
    if s:game_over
	return
    endif

    call s:Trace("\nComputer's turn")

    let cell = s:PickCell()
    if empty(cell)
        return
    endif

    call s:Trace(printf("Opening cell [%d, %d]", cell.row, cell.column))
    call cell.Open()

    let s:comp_grid.num_shots += 1
    let s:comp_grid.shots_remain -= 1

    if cell.IsOccupied()
        call s:Trace("Hit !!!")
	" Opened a cell occupied by a ship
	if !cell.ship.IsSunk()
	    if empty(s:first_hit_cell)
		let s:first_hit_cell = cell
	    endif
	    let s:last_hit_cell = cell
	    call add(s:hit_cells, cell)
	else
            call s:Trace("Sunk !!!")
            " Ship is sunk
	    let s:first_hit_cell = {}
	    let s:last_hit_cell = {}
	    let s:last_dir = ''

            " Remove the cells occupied by the ship from the hit list
	    for ship_cell in cell.ship.cells
		let i = index(s:hit_cells, ship_cell)
		if i != -1
		    call remove(s:hit_cells, i)
		endif
	    endfor

	    if !empty(s:hit_cells)
		let s:first_hit_cell = s:hit_cells[0]
		let s:last_hit_cell = s:hit_cells[0]
	    endif
	endif
    else
        call s:Trace("Miss !!!")
	" Opened an un-occupied cell
	if !empty(s:last_hit_cell)
	    " Previously we have hit a cell, so try going from the first hit
	    " cell in the next turn
	    let s:last_hit_cell = s:first_hit_cell
	    let s:last_dir = s:GetReverseDir(s:last_dir)
	endif
    endif

    " In type 2 of game play, if the last shot is a hit, then let the
    " computer play again.  Otherwise, let the user play.
    if s:game_type == 2
        if !empty(cell) && cell.IsOccupied()
            let s:comp_grid.shots_remain = s:comp_grid.shots_per_turn
        endif
    elseif s:game_type == 3
        " In type 3, the number of shots per turn depends on the number of
        " floating ships
        let ships_floating = s:comp_grid.GetFloatingShipsCount()
        let s:user_grid.shots_per_turn = ships_floating
        let s:user_grid.shots_remain = s:user_grid.shots_per_turn
    endif

    call s:UpdateGameStatus()
endfunction

" ComputerPlay {{{1
" Function to play the computer's turn
function! s:ComputerPlay()
    " Save the cell under cursor in the user grid. Used to restore cursor
    " later
    let save_cell = s:user_grid.GetCellUnderCursor()

    while !s:game_over && s:comp_grid.shots_remain > 0
        call s:ComputerFireOneShot()
    endwhile

    call s:user_grid.PlaceCursorOnCell(save_cell)
endfunction

" UserFireOneShot {{{1
" Handle a shot fired by the user
function! s:UserFireOneShot()
    if s:game_over
	return
    endif

    if !s:user_grid.CursorOnGrid()
        " Cursor is not on the grid. Ignore the shot
	return
    endif

    let cell = s:user_grid.GetCellUnderCursor()

    if cell.IsOpen()
	" Cell is already opened, ignore the shot
	return
    endif

    call cell.Open()

    let s:user_grid.num_shots += 1
    let s:user_grid.shots_remain -= 1

    if s:game_type == 2
        " In type 2 of game play, if the last shot is a hit, then let the user
        " play.  Otherwise, let the computer play.
        if cell.IsOccupied()
            let s:user_grid.shots_remain = s:user_grid.shots_per_turn
        endif
    elseif s:game_type == 3
        " In type 3, the number of shots per turn depends on the number of
        " floating ships
        let ships_floating = s:user_grid.GetFloatingShipsCount()
        let s:comp_grid.shots_per_turn = ships_floating
        let s:comp_grid.shots_remain = s:comp_grid.shots_per_turn
    endif

    " Display the updated game statistics
    call s:UpdateGameStatus()

    if s:game_over
        return
    endif

    " If the user has completed his turn of shots, then let the computer play.
    if s:user_grid.shots_remain == 0
        " Let the computer play it's turn
        call s:ComputerPlay()

        call s:Trace("\nPlayer's turn\n")

        " Go back to the start of the next turn
        let s:user_grid.shots_remain = s:user_grid.shots_per_turn
        let s:comp_grid.shots_remain = s:comp_grid.shots_per_turn
    endif
endfunction

" MoveCursor {{{1
function! s:MoveCursor(dir)
    if !s:user_grid.CursorOnGrid()
        " Cursor is not in the grid. Place it in the middle cell
	let cell = s:user_grid.GetCell(5, 5)
	call s:user_grid.PlaceCursorOnCell(cell)
	return
    endif

    let cell = s:user_grid.GetCellUnderCursor()

    let next_cell = s:user_grid.GetNeighborCell(cell, a:dir)
    if empty(next_cell)
        return
    endif

    call s:user_grid.PlaceCursorOnCell(next_cell)
endfunction

" DrawGrids: Draw the playing grid {{{1
function! s:DrawGrids()
    setlocal expandtab

    let title = "\n" . repeat(' ', 24) . 'Battleship (Type ' .
                \ s:game_type . ', Skill ' . s:skill_level . ")\n\n"
    silent! 0put =title

    let b = repeat(' ', 13) . 'Player Grid'
    let b = b . repeat(' ', 18) . 'Computer Grid' . "\n\n"
    silent! put =b

    let b = ''
    let str = repeat('+-', 10) . '+'
    let str1 = repeat(' ', 8) . str . repeat(' ', 9) . str . "\n"
    let str2 = repeat('| ', 10) . '|'
    for i in ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J']
        let b = b . str1 . repeat(' ', 7) . i . str2 . repeat(' ', 8) .
                    \ i . str2 . "\n"
    endfor

    let str = repeat('+-', 10) . '+'
    let b = b . repeat(' ', 8) . str . repeat(' ', 9) . str . "\n\n"

    let num_label = '1 2 3 4 5 6 7 8 9 10'
    let str = repeat(' ', 9) . num_label . repeat(' ', 10) . num_label
    silent! put=str
    silent! put =b

    let s:user_grid.top = 8
    let s:user_grid.bottom = 26
    let s:user_grid.left = 10
    let s:user_grid.right = 28

    let s:comp_grid.top = 8
    let s:comp_grid.bottom = 26
    let s:comp_grid.left = 40
    let s:comp_grid.right = 58

    " Show the user ships in the computer grid
    call s:comp_grid.ShowFloatingShips()

    let s = repeat(' ', 4)
    let s = s . 'Press <Space> to change fleet placement, <Enter> to accept'
    call append(28, s)

    setlocal nomodified
    setlocal nomodifiable

    redraw!

    " Allow the user to select the desired placement of the fleet.
    while 1
        let ch = getchar()

        if ch == char2nr("\<Space>")
            setlocal modifiable
            call s:comp_grid.RemoveAllShips()
            call s:comp_grid.PlaceShips()
            call s:comp_grid.ShowFloatingShips()
            setlocal nomodified
            setlocal nomodifiable
            redraw!
        endif

        if ch == char2nr("\<Enter>")
            break
        endif
    endwhile

    call s:UpdateGameStatus()
endfunction

" NewGame: Display the board for a new game{{{1
function! s:NewGame()
    " Place the user ships
    let s:user_grid = s:grid.new()
    call s:user_grid.PlaceShips()

    " Place the computer ships
    let s:comp_grid = s:grid.new()
    call s:comp_grid.PlaceShips()

    if has('unix')
        let bname = "\\[Battleship]"
    else
        let bname = "\[Battleship]"
    endif

    let wnum = bufwinnr(bname)
    if wnum == -1
        exe 'new ' . bname
    else
        exe wnum . 'wincmd w'
    endif

    " Make the game window the only displayed window
    only

    setlocal modifiable

    silent! %delete _

    syntax clear

    highlight clear BattleShipHit
    highlight clear BattleShipMiss
    highlight clear BattleShipSink
    highlight clear ShipCell
    highlight clear CellHighlight

    highlight BattleShipMiss ctermfg=Blue ctermbg=White guifg=Blue guibg=White
    syntax match BattleShipMiss '|\zsO\ze|'

    highlight BattleShipHit ctermfg=Red ctermbg=White guifg=Red guibg=White
    syntax match BattleShipHit '|\zsX\ze|'

    highlight BattleShipSink ctermfg=Red ctermbg=Red guifg=Red guibg=Red
    syntax match BattleShipSink '|\zs\*\ze|'

    highlight ShipCell ctermfg=Yellow ctermbg=Yellow guifg=Yellow guibg=Yellow
    syntax match ShipCell '|\zsI\ze|'

    highlight CellHighlight ctermfg=Brown ctermBg=Brown guifg=Brown guibg=Brown
    syntax match CellHighlight '|\zs!\ze|'

    call s:DrawGrids()

    setlocal nomodified
    setlocal buftype=nofile
    setlocal noswapfile
    setlocal nolist
    setlocal nonumber
    setlocal nomodifiable

    let cell = s:user_grid.GetCell(5, 5)
    call s:user_grid.PlaceCursorOnCell(cell)

    nnoremap <silent> <buffer> <CR> :call <SID>UserFireOneShot()<CR>
    nnoremap <silent> <buffer> <RightMouse> :call <SID>UserFireOneShot()<CR>
    nnoremap <silent> <buffer> j :call <SID>MoveCursor('down')<CR>
    nnoremap <silent> <buffer> <Down> :call <SID>MoveCursor('down')<CR>
    nnoremap <silent> <buffer> k :call <SID>MoveCursor('up')<CR>
    nnoremap <silent> <buffer> <Up> :call <SID>MoveCursor('up')<CR>
    nnoremap <silent> <buffer> h :call <SID>MoveCursor('left')<CR>
    nnoremap <silent> <buffer> <Left> :call <SID>MoveCursor('left')<CR>
    nnoremap <silent> <buffer> l :call <SID>MoveCursor('right')<CR>
    nnoremap <silent> <buffer> <Right> :call <SID>MoveCursor('right')<CR>

    nnoremap <silent> <buffer> <PageUp> :call <SID>MoveCursor('top')<CR>
    nnoremap <silent> <buffer> H :call <SID>MoveCursor('top')<CR>
    nnoremap <silent> <buffer> <PageDown> :call <SID>MoveCursor('bottom')<CR>
    nnoremap <silent> <buffer> L :call <SID>MoveCursor('bottom')<CR>
    nnoremap <silent> <buffer> <Home> :call <SID>MoveCursor('first')<CR>
    nnoremap <silent> <buffer> <kHome> :call <SID>MoveCursor('first')<CR>
    nnoremap <silent> <buffer> 0 :call <SID>MoveCursor('first')<CR>
    nnoremap <silent> <buffer> <End> :call <SID>MoveCursor('last')<CR>
    nnoremap <silent> <buffer> <kEnd> :call <SID>MoveCursor('last')<CR>
    nnoremap <silent> <buffer> $ :call <SID>MoveCursor('last')<CR>

    nnoremap <silent> <buffer> q :quit<CR>

    " Initialize information used to track the game
    let s:game_over = 0
    let s:first_hit_cell = {}
    let s:last_hit_cell = {}
    let s:hit_cells = []
    let s:last_dir = ''

    if s:game_type == 3
        let s:user_grid.shots_per_turn = 5
        let s:comp_grid.shots_per_turn = 5
    else
        let s:user_grid.shots_per_turn = 1
        let s:comp_grid.shots_per_turn = 1
    endif

    let s:user_grid.shots_remain = s:user_grid.shots_per_turn
    let s:comp_grid.shots_remain = s:comp_grid.shots_per_turn
endfunction

" StartGame: Process user options and start playing a new game {{{1
function! battleship#StartGame()
    " Get the user skill level
    while 1
        let ans = input("Enter player level (1: Novice or 2: Expert)? ", "1")
        if ans == ''
            return
        endif

        if ans == '1'
            let s:skill_level = 'Novice'
            break
        endif

        if ans == '2'
            let s:skill_level = 'Expert'
            break
        endif

        call s:Warn_msg("\nError: Invalid input. Try agin")
    endwhile

    " Get the type of game
    while 1
        echo "Supported game types"
        echo "Type 1: One shot per turn"
        echo "Type 2: One shot per turn. Additional shots if previous shot is a hit"
        echo "Type 3: Number of shots depend on the number of ships not sunk by Computer"
        let ans = input("Enter game type (1/2/3)? ", "1")
        if ans == ''
            return
        endif

        if ans == '1' || ans == '2' || ans == '3'
            let s:game_type = char2nr(ans) - 48
            break
        endif

        call s:Warn_msg("\nError: Invalid input. Try agin")
    endwhile

    call s:NewGame()
endfunction

" Restore the 'cpo' setting
let &cpo = s:cpo_save
unlet s:cpo_save

" vim: foldenable foldmethod=marker:
