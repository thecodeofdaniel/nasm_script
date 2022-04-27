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
    # grabbing the array passed by arguement in function 'user_input'
    char_input=("$@")

    # Checks for the first character
    if [ "${char_input[0]}" != 'e' ] && [ "${char_input[0]}" != 'd' ]; then  # the first character must always be 'e' or 'd'
        printf "${RED}'e' or 'd' should be the first character${ENDCOLOR}\n"
        user_input
    fi
    
    local file_count=0
    a_count=0

    # Checks for duplicates and checks each character of command
    for ((i = 1 ; i < $sz_of_input ; i++))
    do
        local counter=0

        for (( j = 1 ; j < $sz_of_input ; j++))
        do
            # if there's a match add to the counter
            if [ ${char_input[$i]} == ${char_input[$j]} ]; then
                ((counter++))
            fi

            # if the counter is greater than 1 then ask for user input again
            if [ $counter -gt 1 ]; then 
                printf "${RED}Duplicate ${char_input[$i]}'s!${ENDCOLOR}\n"
                user_input
            fi
        done

        # if character is an integer and not a letter
        if [[ $((char_input[$i])) == ${char_input[$i]} ]]; then

            # Makes sure that file picked is on the list
            if [ ${char_input[$i]} -eq 0 ] || [ ${char_input[$i]} -gt $num_asm_files ]; then
                printf "${RED}${char_input[$i]} is not on the list${ENDCOLOR}\n"
                user_input
            else 
                # otherwise increment the file count
                ((file_count++))
            fi
        # if 'a' is in the command, set a_count = 1
        elif [ "${char_input[$i]}" == 'a' ]; then 
            a_count=1
        # if any other character besides 'l' is included, ask for user input again
        else
            if [ "${char_input[$i]}" != 'l' ]; then 
                printf "${RED}'${char_input[$i]}' is not allowed at position $(($i+1))${ENDCOLOR}\n"
                user_input
            fi
        fi

    done
    
    # If 'a' is chosen, but files are selected in command then ask for user input again
    if [ $a_count == 1 ] && [ $file_count -gt 0 ]; then 
        printf "${RED}Choosing 'a' will select all files${ENDCOLOR}\n"
        user_input
    fi
      
    are_selected_files_valid "${char_input[@]}"
}

function are_selected_files_valid()
{
    char_input=("$@")

    local counter=0

    # if 'a' WASN'T in command, check each file user picked for MAIN
    if [ $a_count == 0 ]; then 
        for ((i = 1 ; i < $sz_of_input ; i++)) 
        do
            # if character IS an integer
            if [[ $((char_input[$i])) == ${char_input[$i]} ]]; then

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

    # If there's no or too many MAIN files then ask for user input again
    if [ $counter == 0 ] || [ $counter -gt 1 ] ; then
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
    while [ $sz_of_input -lt 2 ] || [ $sz_of_input -gt $(($num_asm_files+2)) ]
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
    done

    validate_each_character "${char_input[@]}"
}

function create_linking_command()
{   
    nasm -f elf -g "$1.asm"

    check_for_start=$(cat "$1.asm" | grep '_start' | wc -l)

    if [ $check_for_start == 2 ]; then 
        main_file=$1
        link_cmd+=" '$main_file'.out"
        link_cmd+=" '$main_file'.o"
    else 

        if [ "$1" == "$library_location" ]; then

            library_dir=${library_location%/*}
            library_file=${library_location##*/} 

            o_file_created=$(ls "$library_dir" | grep "\b$library_file.o\b" | wc -l)
        else 
            o_file_created=$(ls | grep "\b$1.o\b" | wc -l)
        fi

        if [ $o_file_created == 1 ]; then 
            link_cmd_other+=" '$1'.o"
        fi
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