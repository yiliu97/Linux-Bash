# Linux-Bash
This repository contains programms in Bash.

## minesweeper.sh

A classic puzzle game with extreme popularity.
Implemented the basic function in Bash.  
At the beginning of the game, you are able to select the difficulty level:  
easy (15 mines in 100 cells), normal (20 mines in 100 cells), hard (30 mines in 100 cells).  
If the input is invalid (i.e. not one of the levels in lower case), the game will start in default mode(normal).  

In the game, you can uncover the cells by entering coordinates. 
If the cell containss a mine, the game will ends and displays your score (i.e. the number of cells you have uncovered without mines).  
The uncovered cell will display the number of adjacent mines will be displayed.
If a cell has no adjacent mines, all adjacent cells will automatically be uncovered.  
If you managed to all the squares that do not contain mines, you win the game and your score will be displayed.
