#!/bin/bash

library_location="/home/$(whoami)/Desktop/csci150_AssemblyLanguage/z_library/library.asm"

library_location="${library_location%.asm}"

# Colors for when outputting text
ENDCOLOR="\e[0m"
BOLD="\e[1m"
DIM="\e[2m"
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"

function validate_each_character()
{
    char_input=("$@") # accepting the user's array characters from input

    for ((i = 0 ; i < $sz_of_input ; i++)); do

        # for first character input 
        if [ $i == 0 ]; then 
            if [ "${char_input[0]}" != 'e' ] && [ "${char_input[0]}" != 'd' ]; then  # the first character must always be 'e' or 'd'
                printf "${RED}'e' or 'd' should be the first character${ENDCOLOR}\n"
                user_input
            fi
        fi

        # for characters in between first and last character (if input size is only 2, then it'll skip this block)
        if [ $i -gt 0 ] && [ $i -lt $(($sz_of_input - 1)) ]
        then
            # checks for duplicate integers
            if [[ $((char_input[$i])) == ${char_input[$i]} ]] # if an integer
            then
                if [ "${char_input[$i]}" == "${char_input[$i-1]}" ]; then 
                    printf "${RED}Selected Duplicate Files${ENDCOLOR}\n"
                    user_input; 
                fi
            fi
        fi

        # for the last character input 
        if [ $i -eq $(($sz_of_input - 1)) ]
        then
            # if NOT an integer
            if [[ $((char_input[$i])) != ${char_input[$i]} ]]   
            then

                if [ $sz_of_input == 2 ]                        # if the user only entered two characters
                then            
                    if [ "${char_input[$i]}" != 'a' ]; then     # If user only eneted two characters, 'a' should be the last character
                        printf "${RED}The second character should be a '#' on the list or 'a' for all files${ENDCOLOR}\n"
                        user_input
                    fi
                else                                                          
                    if [ "${char_input[$i]}" != 'l' ]; then     # otherwise, the last char must be 'l'
                        printf "${RED}The last character should be a '#' on the list or 'l' for including library${ENDCOLOR}\n"
                        user_input
                    fi
                fi
            fi
            
            # if IT IS an integer
            if [[ $((char_input[$i])) == ${char_input[$i]} ]]
            then  
                if [ ${char_input[$i-1]} == 'a' ]; then         # If number is entered after inputting 'a'
                    printf "${RED}'a' will select all, no need to select number ${ENDCOLOR}\n"
                    user_input
                fi
            fi

            # checks for duplicate files picked
            if [[ $((char_input[$i])) == ${char_input[$i]} ]]   # if IT IS an integer
            then
                if [ "${char_input[$i]}" == "${char_input[$i-1]}" ]; then 
                    printf "${RED}Selected Duplicate Files!${ENDCOLOR}\n"
                    user_input; 
                fi
            fi
        fi

    done
}

function are_selected_files_valid()
{
    char_input=("$@")

    local counter=0

    # checks if there are too many main files selected
    for ((i = 1 ; i < $sz_of_input ; i++)) 
    do
        if [[ $((char_input[$i])) == ${char_input[$i]} ]]; then     # if IT IS an integer

            # Looks to see if integer selected is on the list
            if [ ${char_input[$i]} -eq 0 ] || [ ${char_input[$i]} -gt $num_asm_files ]; then
                printf "${RED}Your selected file is not on the list${ENDCOLOR}\n"
                user_input
            fi

            int=${char_input[$i]}
            check_for_start=$(cat "${asm_file[$int-1]}.asm" | grep "_start" | wc -l)

            if [ $check_for_start == 2 ]; then counter=$((counter+1)); fi       # increments counter if main file is found within user input
        fi
    done

    # if 'a' is selected then check the amount of main programs in directory
    if [ ${char_input[1]} == 'a' ]; then
        for ((i = 0 ; i < $num_asm_files ; i++)); do 

            check_for_start=$(cat "${asm_file[$i]}.asm" | grep "_start" | wc -l)

            if [ $check_for_start == 2 ]; then counter=$((counter+1)); fi       # increments counter if main file is found within user input
        done
    fi

    if [ $counter -gt 1 ]; then
        printf "${RED}Only select one main program${ENDCOLOR}\n"
        user_input
    fi

    if [ $counter == 0 ]; then
        printf "${RED}Select one main program${ENDCOLOR}\n"
        user_input
    fi
}

function print_asm_files()
{
    num_asm_files=$(ls | grep '\b.asm\b' | wc -l)

    for ((i = 0 ; i < $num_asm_files ; i++)); do
        asm_file[$i]=$(ls | grep '\b.asm\b' | grep '.asm' -n | grep $(($i+1)) | cut -c 3-)   # only getting .asm files from current directory into array
        asm_file[$i]=${asm_file[$i]%.*}                                                  # getting the names of files without the .asm extension
    done
    
    printf '\n'
    for ((i = 0 ; i < $num_asm_files ; i++)); do
        printf "${BOLD}${BLUE}$(($i+1)):${ENDCOLOR} ${asm_file[$i]}.asm\n"
    done 
}

function user_input()
{    
    sz_of_input=0
    while [ $sz_of_input -lt 2 ]
    do
        printf "\nEnter: ${BOLD}${YELLOW}"
        read -a arr             # reading from user input
        printf "${ENDCOLOR}"

        sz_of_input=${#arr[@]}  # getting the number of characters from string besides 'space'
        char_input=($sz_of_input) # setting up array with its size

        local counter=0               # setting up counter for for-loop
        for elem in ${arr[@]}
        do
            char_input[$counter]=$elem
            ((counter++))
        done

        validate_each_character  "${char_input[@]}"
        are_selected_files_valid "${char_input[@]}"
    done
}

function create_linking_command()
{   
    nasm -f elf -g "$1.asm"

    check_for_start=$(cat "$1.asm" | grep '_start' | wc -l)

    if [ $check_for_start == 2 ]; then 
        main_file=$1
        link_cmd+=" '$main_file'.out"
    fi

    if [ "$1" == "$library_location" ] 
    then
        library_dir=${library_location%/*}
        library_file=${library_location##*/} 

        o_file_created=$(ls "$library_dir" | grep "\b$library_file.o\b" | wc -l)
    else 
        o_file_created=$(ls | grep "\b$1.o\b" | wc -l)
    fi

    if [ $o_file_created == 1 ]; then 
        link_cmd_other+=" '$1'.o"
    fi
}

function remove_obj_files()
{
    # counting the number of object files within directory
    num_obj_files=$(ls | grep "\b.o\b" | wc -l)

    # if the number of object files is greater than 0
    if [ $num_obj_files -gt 0 ]
    then 
        # creating an empty array
        o_files=()

        # putting each object file into empty array
        for ((i = 0 ; i < ${num_obj_files} ; i++)); do
            o_files[$i]=$(ls | grep "\b.o\b" | grep '.o' -n | grep $(($i+1)) | cut -c 3-)
        done

        # removing all object files
        for ((i = 0 ; i < ${num_obj_files} ; i++)); do
            rm "${o_files[$i]}"
        done
    fi
}

function remove_previous_out_file()
{
    num_out_file=$(ls | grep "\b$main_file.out\b" | wc -l) 

    if [ $num_out_file == 1 ]; then 
        rm "$main_file.out"; 
    fi
}

##############
# MAIN BELOW #
##############

printf "${DIM}\nYou can always exit the script with: ${BOLD}${YELLOW}Ctrl + C${ENDCOLOR}\n"

print_asm_files
user_input

link_cmd="ld -m elf_i386 -o"
link_cmd_other=" "

for ((i = 1 ; i < $sz_of_input ; i++)); do

    char=${char_input[$i]}

    if [[ $((char)) == $char ]]; then 
        int=$char
        create_linking_command "${asm_file[$int-1]}"
    fi
    
    if [ $char == 'a' ]; then
        for ((j = 0 ; j < $num_asm_files ; j++)); do
            create_linking_command "${asm_file[$j]}"    # nasm's all .asm files
        done
    fi

    if [ $char == 'l' ]; then 
        create_linking_command "$library_location"
    fi

done

remove_previous_out_file

main_obj_file_created=$(ls | grep "\b$main_file.o\b" | wc -l)

if [ $main_obj_file_created == 1 ]; then 

    link_cmd="$link_cmd$link_cmd_other"     # creating the full linking command by combining strings

    eval "$link_cmd"                        # executing linking command

    num_out_file=$(ls | grep "\b$main_file.out\b" | wc -l)      # finding if the .out file was created in directory

    if [ $num_out_file == 1 ]; then 

        remove_obj_files

        if [ ${char_input[0]} == 'e' ]; then

            eval "./'$main_file'.out"

            if ! pgrep -x "gedit" > /dev/null; then
                printf "Exited ${GREEN}$main_file.out${ENDCOLOR}\n"
            fi
            
        else
            eval "gdb --quiet '$main_file'.out"
        fi
    fi
fi