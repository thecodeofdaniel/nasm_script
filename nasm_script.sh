#!/bin/bash

library_location="/home/$(whoami)/Desktop/csci150_AssemblyLanguage/z_library/library.asm"
library_location="${library_location%.asm}"

display_how_to_exit=true

# Colors/TextFormat for when outputting text
EC="\e[0m"
BOLD="\e[1m"
DIM="\e[2m"
RED="\e[31m"
GRN="\e[32m"
YELW="\e[33m"
BLUE="\e[34m"

function validate_each_character()
{
    # grabbing the array passed by arguement in function 'user_input'
    char_input=("$@")

    # checks for the first character
    if [ "${char_input[0]}" != 'e' ] && [ "${char_input[0]}" != 'd' ]; then
        printf "${RED}'e' or 'd' should be the first character${EC}\n"
        user_input
    fi
    
    local file_count=0
    a_count=0

    # Goes through each character in command 
    for ((i = 1 ; i < $sz_of_input ; i++))
    do
        # if character is an integer
        if [[ ${char_input[$i]} =~ ^[0-9]+$ ]]; then

            # makes sure that file picked is on the list
            if [ ${char_input[$i]} == 0 ] || [ ${char_input[$i]} -gt $num_asm_files ]; then
                printf "${RED}${char_input[$i]} is not on the list${EC}\n"
                user_input
            else 
                # otherwise increment the file count
                ((file_count++))
            fi
        # if 'a' is in the command increment a_counter
        elif [ "${char_input[$i]}" == 'a' ]; then 
            ((a_count++))
        # if any other character besides 'l' is included, ask for user input again
        elif [ "${char_input[$i]}" != 'l' ]; then
            printf "${RED}'${char_input[$i]}' is not allowed at position $(($i+1))${EC}\n"
            user_input
        fi

    done
    
    # if 'a' is chosen, but files are selected in command then ask for user input again
    if [ $a_count == 1 ] && [ $file_count -gt 0 ]; then 
        printf "${RED}Choosing 'a' will select all files${EC}\n"
        user_input
    # if there are multiple 'a's in command then ask for user input again
    elif [ $a_count -gt 1 ]; then 
        printf "${RED}Duplicate 'a's in command${EC}\n"
        user_input
    fi
      
    check_for_main
}

function check_for_main()
{
    local counter=0

    # if 'a' WASN'T in command, check each file user picked for MAIN
    if [ $a_count == 0 ]; then 
        for ((i = 1 ; i < $sz_of_input ; i++)) 
        do
            # if character IS an integer
            if [[ ${char_input[$i]} =~ ^[0-9]+$ ]]; then

                int=${char_input[$i]}
                
                # checks if .asm file is a MAIN
                check_for_start=$(cat "${asm_file[$int-1]}.asm" | grep "_start" | wc -l)

                # increments counter if .asm file is MAIN
                if [ $check_for_start == 2 ]; then 
                    counter=$((counter+1)) 
                fi      
            fi
        done
    fi
    
    # if 'a' WAS in command check each file for MAIN file
    if [ $a_count == 1 ]; then 
    
        for ((i = 0 ; i < $num_asm_files ; i++))
        do
            # checks if .asm file is a MAIN file
            check_for_start=$(cat "${asm_file[$i]}.asm" | grep "_start" | wc -l)

            # increments counter if .asm file is MAIN file
            if [ $check_for_start == 2 ]; then
                counter=$((counter+1)) 
            fi
        done
    fi

    # if there's no or too many MAIN files then ask for user input again
    if [ $counter == 0 ] || [ $counter -gt 1 ] ; then
        printf "${RED}Select one main program${EC}\n"
        user_input
    else    
    # otherwise go to this function
        evaluate_command
    fi
}

function print_asm_files()
{
    # grabs the number of .asm file in current directory
    num_asm_files=$(ls | grep '\b.asm\b' | wc -l)

    if [ $num_asm_files == 0 ]; then
        printf "\n${BOLD}${RED}No .asm files here!${EC}\n"
        exit
    fi

    # Displays user how to exit script
    if [ $display_how_to_exit = true ]; then 
        printf "\n${DIM}Exit the script with: ${BOLD}${YELW}Ctrl + C${EC}\n"
    fi

    printf '\n'

    # puts the names of the .asm files in array and outputs list onto screen
    for ((i = 0 ; i < $num_asm_files ; i++)); do
        asm_file[$i]=$(ls | grep '\b.asm\b' | grep '.asm' -n | grep $(($i+1)) | cut -c 3-)
        asm_file[$i]=${asm_file[$i]%.*}                                                  
        printf "${BOLD}${BLUE}$(($i+1)):${EC} ${asm_file[$i]}.asm\n"
    done
}

function user_input()
{    
    # using while-loop because there is no do-while-loop in bash
    sz_of_input=0
    local arr=()
    while [ $sz_of_input -lt 2 ] || [ $sz_of_input -gt $(($num_asm_files+2)) ]
    do
        # grabbing each character of user input and putting them into array
        printf "\nEnter: ${BOLD}${YELW}"
        read -r -a arr             
        printf "${EC}"

        # getting the number of characters from string besides 'space'
        sz_of_input=${#arr[@]}

        # Adding the abilty to clear screen 
        if [ $sz_of_input == 1 ] && [ "${arr[0]}" == 'c' ]; then
            clear
            print_asm_files
        # Other wise if input is too small or too great, prompt error message
        elif [ $sz_of_input -lt 2 ]; then
            printf "${RED}Command should be greater than one character${EC}\n"
        elif [ $sz_of_input -gt $(($num_asm_files+2)) ]; then
            printf "${RED}Command should be less than $(($num_asm_files+3)) characters${EC}\n"
        fi
    done

    validate_each_character "${arr[@]}"
}

function create_linking_command()
{   
    # passing in name of file from parameter
    local file_name=$1
    
    # '-g' will allow the .out file to be debugged
    if [ "${char_input[0]}" = 'd' ]; then
        nasm -f elf -g "$file_name.asm"
    else 
        nasm -f elf "$file_name.asm"
    fi

    # this finds which file is MAIN and determines the name of the .out file
    check_for_start=$(cat "$file_name.asm" | grep '_start' | wc -l)

    # if main file is found then place them first in linking command
    if [ $check_for_start == 2 ]; then 
        main_file=$file_name
        link_cmd+=" '$main_file'.out"
        link_cmd+=" '$main_file'.o"
    else 

        # the following code determines if object file was created...
        if [ "$file_name" == "$library_location" ]
        then
            library_dir=${library_location%/*}
            library_file=${library_location##*/} 

            o_file_created=$(ls "$library_dir" | grep "\b$library_file.o\b" | wc -l)
        else 
            o_file_created=$(ls | grep "\b$file_name.o\b" | wc -l)
        fi

        # if so, then put it in the linking command's other half
        if [ $o_file_created == 1 ]; then 
            link_cmd_other+=" '$file_name'.o"
        fi
    fi
}

function remove_obj_files()
{
    # counting the number of object files within directory
    num_obj_files=$(ls | grep "\b.o\b" | wc -l)

    # if there are obj files
    if [ $num_obj_files -gt 0 ]
    then 
        # grabbing the name of the obj file and removing it
        for ((i = 0 ; i < ${num_obj_files} ; i++)); do
            o_file=$(ls | grep "\b.o\b" | grep '.o' -n | grep '1:' | cut -c 3-)
            rm "$o_file"
        done
    fi
}

function remove_previous_out_file()
{
    # code below deletes the previous main .out file if there was one created
    local num_out_file=$(ls | grep "\b$main_file.out\b" | wc -l) 

    if [ $num_out_file == 1 ]; then 
        rm "$main_file.out"; 
    fi
}

function evaluate_command()
{
    # creating a string for the link command
    link_cmd="ld -m elf_i386 -o"
    link_cmd_other=""

    # going through each chracter in order to create the linking command
    for ((i = 1 ; i < $sz_of_input ; i++)); do

        local char=${char_input[$i]}

        if [[ $char =~ ^[0-9]+$ ]]; then 
            int=$char
            create_linking_command "${asm_file[$int-1]}"
        fi
        
        if [ $char == 'a' ]; then
            for ((j = 0 ; j < $num_asm_files ; j++)); do
                create_linking_command "${asm_file[$j]}" 
            done
        fi

        if [ $char == 'l' ]; then 
            create_linking_command "$library_location"
        fi

    done
}

function execute_debug()
{
    remove_previous_out_file

    # determines if main object file was created
    local main_obj_file_created=$(ls | grep "\b$main_file.o\b" | wc -l)

    if [ $main_obj_file_created == 1 ]
    then 
        # executes the linking command with the string created in "evaluate command" function
        eval "$link_cmd$link_cmd_other"

        # determines if .out file was created
        local num_out_file=$(ls | grep "\b$main_file.out\b" | wc -l)

        if [ $num_out_file == 1 ]
        then 
            # removes obj files once .out file was created
            remove_obj_files
            # if user chose 'e' then execute the main .out file
            if [ ${char_input[0]} == 'e' ]
            then
                eval "./'$main_file'.out"

                if ! pgrep -x "./'$main_file'.out" > /dev/null; then
                    printf "Exited ${GRN}$main_file.out${EC}\n"
                fi 
            # otherwise debug the main .out file
            else
                eval "gdb --quiet '$main_file'.out"
            fi
        fi
    fi
}

function continue?()
{
    printf "\nPress ${BOLD}${YELW}Enter${EC} to continue: ${BOLD}${YELW}"
    read -r answer; printf "${EC}"
    if [[ $answer != '' ]]; then exit; fi
}

### MAIN ###

# Allows script to loop until user exits
function main()
{
    print_asm_files
    user_input
    execute_debug

    continue?
    
    main
}

main