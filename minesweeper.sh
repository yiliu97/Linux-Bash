#!/bin/bash

#total score
score=0

#the array cells stores the status of each cell
declare -a cells

#the array mines stores if the cell contains a mine
declare -a mines

#the array shadow stores if the cell is opened
declare -a shadow

#positions of mines
declare -a mines_position

select_level()
{
	#number of mines in the game
	mines_number=0

	printf '%s \n%s \n%s \n' "easy - 15 mines" "normal - 20 mines" "hard - 25 mines"

	read -p "Please enter a level(in lower case): " game_level

	case ${game_level} in
		"easy" ) mines_number=15;;
		"normal" ) mines_number=20;;
		"hard" ) mines_number=25;;
		* ) 
		{
			mines_number=20 
			printf '%s \n' "Start in default level (i.e. normal level)"
		};;
       esac

}

#allocate mines
allocate_mines()
{
	local j=0
	
	for j in $(seq 0 $[$mines_number-1]); do
		#if the input value is equal to a position, the return value is 1
		if [[ "${mines_position[$j]}" -eq "$1" ]];then
			return 1
		fi
	done

}

#initialization function
init_game()
{
	local i=0
	#generate random numbers, the value of each number represents position of a mine
	readarray mines_position < <(seq 0 99 | shuf | head -$mines_number)
	
	#set the cells of the game board
	for i in $(seq 0 99); do
		shadow[$i]=1; #the cell is covered if shadow=1
		#call function to allocate mines
		allocate_mines $i
		mines[i]=$?
	done
	#draw the gameboard
	draw_gameboard
}

#revealed the number of mines adjacent to a cell
count_mines()
{ 
	declare -i position_tmp
	
	#get the input value of a coordinate
	position_tmp=$1 
	
	#get the column and row of the input
	local col=`expr $position_tmp % 10`
	local row=`expr $position_tmp / 10`
	
	#count the number of mines
	local mines_counter=0

	#for input coordinate a,
	#the adjacent coordinates will be
	
	#  a-11 | a-10 | a-9
	# --------------------
	#  a-1  |  a   | a+1
	# --------------------
	#  a+9  | a+10 | a+11
	
	#get the maximum and minimum values
	local col_min=`expr $col - 1`
	#offset the values
	offset_value $col_min
	col_min=$?
 
	local col_max=`expr $col + 1`
	offset_value $col_max
	col_max=$?
	local row_min=`expr $row - 1`
	offset_value $row_min
	row_min=$?
	local row_max=`expr $row + 1`
	offset_value $row_max
	row_max=$?
    
	#the Bash does not support multidimensional arrays
	#two for loops are used to simulate a 2d array
	#scan the 8 adjacent cells
	for i in $(seq $row_min $row_max); do
		for j in $(seq $col_min $col_max); do
		
			local coord_tmp=0
			#calculate the coordinate
			coord_tmp=$(((10*i)+j))
			#the original cell will not be checked
			if [[ $coord_tmp -ne $position_tmp ]];then
				
				#check a cell
				check_cell $coord_tmp
				((mines_counter+=$?))
				
			fi
		done
	done
	
	#return the number of the adjacent mines
    return $mines_counter
}

#check a cell
check_cell()
{ 
	#the input coordinate
    local coord_buf=$1 

	#if there's a mine in the cell, return 1, otherwise return 0
	if [[ "${mines[$coord_buf]}" -eq 1 ]];then
		return 1
	else
		return 0
    fi

}

#make sure the coordinates does not exceeds the edge
offset_value()
{
  if [[ $1 -gt 9 ]];then
      return 9
  elif [[ $1 -lt 0 ]];then
      return 0
  else
      return $1
  fi

}

#open a cell
open_cell()
{ 
	local i=0
	local j=0

	#get the input value of coordinate
	local posit_buf=$1 
	
	#get the column and row
	local col=`expr $posit_buf % 10`
	local row=`expr $posit_buf / 10`

	#the shadow is removed
	shadow[$posit_buf]=0
	
	#scan adjacent cells
    count_mines $posit_buf
	
	#get the number of adjacent mines
    local mines_adj=$?

	#if the cell contains a mine
	if [[ "${mines[$posit_buf]}" -eq 1 ]];then
		#the game will be ended and display your score
		cells[$posit_buf]="X"
		draw_gameboard
		printf '\e[31m%s\e[0m\n%s %d\n'  "GAME OVER" "Your Score:" "$score"
		exit 0
    
	#if the cell is not a mine without mines revealed
	#it will recursively open the adjacent cells
    elif [[ $mines_adj -eq 0 ]];then
		
		#display the number
		cells[$posit_buf]=$mines_adj
		#the score will plus 1 for each cell opened
		((score+=1))

		local col_min=`expr $col - 1`
		offset_value $col_min
		col_min=$?
      
		local col_max=`expr $col + 1`
		offset_value $col_max
		col_max=$?
   
		local row_min=`expr $row - 1`
		offset_value $row_min
		row_min=$?

		local row_max=`expr $row + 1`
		offset_value $row_max
		row_max=$?

		#recursively open the adjacent cells
		for i in $(seq $row_min $row_max); do
			for j in $(seq $col_min $col_max); do
				local coord_tmp=0
				#calculate the coordinate
				coord_tmp=$(((10*i)+j))
				#if the cell has not been opened
				if [[ "${shadow[$coord_tmp]}" -eq 1 ]];then
					open_cell $coord_tmp
				fi
			done
		done
		
	#if adjacent mines exist	
    elif [[ $mines_adj -gt 0 ]];then
		#display the number
		cells[$posit_buf]="$mines_adj"
		#plus 1 to the score 
		((score+=1))
    fi
 

}


#draw the gameboard
#the game board is 10*10, containing 100 cells
draw_gameboard()
{
	counter=0
  
	#clear the screen
	printf "\e[2J\e[H" 
  
	#print the title for each column
	printf '%s' "     a   b   c   d   e   f   g   h   i   j"
	#print the split line
	printf '\n   %s\n' "-----------------------------------------"
  
	for row in $(seq 0 9); do
		printf '%d  ' "$row"
		for col in $(seq 0 9); do

			check_covered_cell $counter

			case ${cells[$counter]} in
			#covered cells are represented by blue question mark
			"?" ) printf '%s \e[34m%s\e[0m ' "|" "${cells[$counter]}";;
			#mines are represented by red X
			"X" ) printf '%s \e[31m%s\e[0m ' "|" "${cells[$counter]}";;
			#numbers are printed in white
			* ) printf '%s %s ' "|" "${cells[$counter]}";;
			esac
			((counter+=1))
		done
		printf '%s\n' "|"
		#print the bottom line
		printf '   %s\n' "-----------------------------------------"
	done
	printf '\n'
}

#all the covered cells are represeted by "?"
check_covered_cell()
{
  local e=$1  
    if [[ "${shadow[$e]}" -eq 1 ]];then
      cells[$counter]="?"
    fi
}


#convert the input coordinates
convert_coordinates()
{
	#get the column and row
	local col_tmp=${coord_in:0:1}
	local row_tmp=${coord_in:1:1}

	#if the entered column is not a~j, the input is invalid
	case $col_tmp in
		"a" | "A" ) column=0;;
		"b" | "B" ) column=1;;
		"c" | "C" ) column=2;;
		"d" | "D" ) column=3;;
		"e" | "E" ) column=4;;
		"f" | "F" ) column=5;;
		"g" | "G" ) column=6;;
		"h" | "H" ) column=7;;
		"i" | "I" ) column=8;;
		"j" | "J" ) column=9;;
		* ) {
				printf '%s\n' "Invalid Input"
				return 0
			};;
	esac

	#calculate the coordinate
	coordinate=$(((10*row_tmp)+column))

	#if the cell is covered, open the cell and refresh gameboard
	if [[ "${shadow[$coordinate]}" -eq 1 ]];then
		open_cell $coordinate
		draw_gameboard
		#if only the mines remain, end the game and print score
		if [[ $score -eq $[100-$mines_number] ]];then
			printf '\e[31m%s\e[0m\n%s %d\n' "You Win!" "Your Score:" "$score"
			exit 0
		fi
	#if the cell is not covered, the input is invalid
    else
		printf '%s\n' "Invalid Input"
    fi

}


#main functions

select_level

init_game

while true;do

echo "Hint: To choose column- a, row- 0, give input - a0"
read -p "enter the coordinates: " coord_in
convert_coordinates

done

