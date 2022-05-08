#!/bin/bash

library_location="/home/$(whoami)/Desktop/csci150_AssemblyLanguage/z_library/library.asm"

# If set to true then give name of .asm file
let_script_find_library=false
lib_name="library.asm"

# home/user1/Desktop/csci150_AssemblyLanguage/z_library/library

display_how_to_exit=true
clear_after_exit=false

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
    # local variables are visible to the functions they call 
    local errors=0
    local file_count=0

    # checks for the first character
    if [ "${char_input[0]}" != 'e' ] && [ "${char_input[0]}" != 'd' ]; then
        printf "${RED}'e' or 'd' should be the first character${EC}\n"
        ((errors++))
    fi

    # goes through the rest of the characters
    for ((i = 1 ; i < $sz_of_input ; i++))
    do
        # if character is an integer
        if [[ ${char_input[$i]} =~ ^[0-9]+$ ]]; then

            # check if integer selected is on the list
            if [ ${char_input[$i]} == 0 ] || [ ${char_input[$i]} -gt $num_asm_files ]; then
                printf "${RED}${char_input[$i]} is not on the list${EC}\n"
                ((errors++))
            else 
                # otherwise increment the file count
                ((file_count++))
            fi
        # otherwise that character must only be 'l'
        elif [ "${char_input[$i]}" != 'l' ]; then
            printf "${RED}'${char_input[$i]}' is not allowed at position $(($i+1))${EC}\n"
            ((errors++))
        fi
    done

    # if there are no errors continue to the next function
    if [ $errors -gt 0 ]; then 
        user_input
    else
        check_for_main
    fi
}

function check_for_main()
{
    # This will keep track of the amount of main files in command
    local counter=0

    # if user selected files in command
    if [ $file_count != 0 ]; then 
        for ((i = 1 ; i < $sz_of_input ; i++)) 
        do
            # if character is an integer
            if [[ ${char_input[$i]} =~ ^[0-9]+$ ]]; then

                int=${char_input[$i]}
                
                # checks .asm file has "_start" text
                check_for_start=$(cat "${asm_file[$int-1]}.asm" | grep "_start" | wc -l)

                # increments counter if .asm file is a main file
                if [ $check_for_start == 2 ]; then 
                    counter=$((counter+1)) 
                fi      
            fi
        done
    fi
    
    # if command has no files selected
    if [ $file_count == 0 ]; then 

        # checking all .asm files in directory
        for ((i = 0 ; i < $num_asm_files ; i++))
        do
            # checks .asm file has "_start" text
            check_for_start=$(cat "${asm_file[$i]}.asm" | grep "_start" | wc -l)

            # increments counter if .asm file is a main file
            if [ $check_for_start == 2 ]; then
                counter=$((counter+1)) 
            fi
        done
    fi

    # if there's only one main file in command then continue to the next function
    if [ $counter == 0 ]; then
        printf "${RED}Select one main file${EC}\n"
        user_input
    elif [ $counter -gt 1 ]; then
        printf "${RED}You have selected $counter main files, only select one${EC}\n"
        user_input
    else
        # saving the command and file count in case user wants to run the program again
        prev_file_count=$file_count; prev_char_input=("${char_input[@]}")
        evaluate_command "$file_count" "${char_input[@]}"
    fi
}
function prev_cmnd()
{
    if [ ${#prev_char_input[@]} -gt 0 ]; then
        printf '\033[1A\033[K' # removing the empty "Enter: " line
        # displays the previous command
        printf "Enter: ${BOLD}${DIM}${YELW}"; echo -n ${prev_char_input[@]}; printf "${EC}\n"
        # sends the command the evaluate_command function skipping the 'validate_each_character'
        evaluate_command "$prev_file_count" "${prev_char_input[@]}"
    else
        # if the previous command is empty
        printf "${RED}No previous command${EC}\n"
        user_input
    fi
}
function print_asm_files()
{
    # grabs the number of .asm file in current directory
    num_asm_files=$(ls | grep '\b.asm\b' | wc -l)

    # If there are no .asm files in directory
    if [ $num_asm_files == 0 ]; then
        printf "${BOLD}${RED}No .asm files here!${EC}"; sleep 1; clear; exit
    fi

    # Displays user how to exit script
    if [ $display_how_to_exit = true ]; then 
        printf "${DIM}Exit the script with: ${BOLD}${YELW}Ctrl + C${EC}\n\n"
    fi

    # puts the names of the .asm files in array and outputs list onto screen
    for ((i = 0 ; i < $num_asm_files ; i++)); do
        asm_file[$i]=$(ls | grep '\b.asm\b' | grep '.asm' -n | grep $(($i+1)) | cut -c 3-)
        asm_file[$i]=${asm_file[$i]%.*}                                                  
        printf "${BOLD}${BLUE}$(($i+1)).${EC} ${asm_file[$i]}.asm\n"
    done
}

function user_input()
{    
    # grabbing each character of user input and putting them into array
    printf "\nEnter:${BOLD}${YELW}"; read -r -p ' ' -a char_input; printf "${EC}"

    # getting the number of characters from string besides 'space'
    sz_of_input=${#char_input[@]}

    # being able to use the previous command by leaving the command blank
    if [ $sz_of_input == 0 ]; then
        prev_cmnd
    # adding the abilty to clear screen 
    elif [ $sz_of_input == 1 ] && [ "${char_input[0]}" == 'c' ]; then
        clear; print_asm_files; user_input
    else
        validate_each_character
    fi
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

function find_library()
{
    # finding the library file in the user's home directory
    if [ $let_script_find_library = true ]; then
        # grabbing the home directory 
        home="/home/$(whoami)"
        # more efficient way of cd'ing to the home dir
        pushd $home > /dev/null
        library_location=$(find $home -type f -name $lib_name -not -path "./.local/share/Trash/*" | cut -f 1 -d '.')
        # returning to the previous dir
        popd > /dev/null
    # otherwise use the location given on line 3 of the script
    else 
        library_location="${library_location%.asm}"
    fi
}

function evaluate_command()
{
    # accepting the arguements passed in
    file_count=$1
    shift
    char_input=("$@")

    # creating a string for the link command
    link_cmd="ld -m elf_i386 -o"
    link_cmd_other=""

    if [ $file_count == 0 ]; then
        for ((i = 0 ; i < $num_asm_files ; i++)); do
            create_linking_command "${asm_file[$i]}" 
        done
    fi

    # going through each chracter in order to create the linking command
    for ((i = 1 ; i < ${#char_input[@]} ; i++)); do

        local char=${char_input[$i]}

        if [[ $char =~ ^[0-9]+$ ]]; then 
            int=$char
            create_linking_command "${asm_file[$int-1]}"
        fi
        
        if [ $char == 'l' ]; then
            find_library 
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

function exit_script()
{
    # This will remove the "Enter: " prompt
    echo; printf '\033[1A\033[K'  
    # If user chooses so, they can clear screen when exiting script
    if [ $clear_after_exit = true ]; then clear; fi
    exit 0
}

### MAIN ###

# trap keyword catches signals that happen during execution
# Ctrl + C signals SIGINT 
trap exit_script SIGINT

# Allows script to loop until user exits
function main()
{
    print_asm_files
    user_input
    execute_debug

    echo; main
}

clear
main