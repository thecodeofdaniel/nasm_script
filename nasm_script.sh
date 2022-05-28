#!/bin/bash

lib_dir="$HOME/PATH/TO/LIBRARY/FOLDER"

# set to true if you want to save your inputs even after exiting script
create_input_history=false
# Set to false if you want to remove "Exit the script with: Ctrl + C" line
display_how_to_exit=true
# Set to true to both if you want to keep object and .out files
keep_obj_files=false
keep_out_files=false

# Colors/TextFormat for when outputting text
EC="\e[0m"
BOLD="\e[1m"
DIM="\e[2m"
RED="\e[31m"
GRN="\e[32m"
YELW="\e[33m"
BLUE="\e[34m"
RML="\e[1A\e[K"

function validate_each_character()
{
    local errors=0
    local sel_file_count=0

    # checks the first character
    if [ "${char_input[0]}" != 'e' ] && [ "${char_input[0]}" != 'd' ]; then
        printf "${RED}'e' or 'd' should be the first character${EC}\n"; ((errors++))
    fi

    # checks the rest of the characters
    for ((i = 1 ; i < $sz_of_input ; i++)); do
        # character must be an integer
        if [[ ${char_input[$i]} =~ ^[0-9]+$ ]]; then

            # check if integer selected is on the list
            if [ ${char_input[$i]} == 0 ] || [ ${char_input[$i]} -gt $num_asm_files ]; then
                printf "${RED}${char_input[$i]} is not on the list${EC}\n"; ((errors++))
            else 
                ((sel_file_count++))
            fi
        else
            printf "${RED}'${char_input[$i]}' is not allowed at position $(($i+1))${EC}\n"; ((errors++))
        fi
    done

    # if user has not selected any files then add all .asm files to the command
    if [ $sel_file_count == 0 ]; then 
        for ((i = 0 ; i < $num_asm_files ; i++)); do 
            char_input[$sz_of_input+$i]=$(($i+1))
        done
    fi

    # if there are no errors continue to the next function
    if [ $errors != 0 ]; then user_input; else check_for_main; fi
}

function check_for_main()
{
    # This will keep track of the amount of main files in command
    local counter=0

    for ((i = 1 ; i < ${#char_input[@]} ; i++)); do
        # if character is an integer
        if [[ ${char_input[$i]} =~ ^[0-9]+$ ]]; then

            int=${char_input[$i]}

            # checks .asm file has "_start" text
            check_for_start=$(cat "${asm_file[$int-1]}.asm" | grep "_start" | wc -l)

            # increments counter if .asm file is a main file
            if [ $check_for_start == 2 ]; then counter=$((counter+1)); fi      
        fi
    done

    # if there's only one main file in command then continue to the next function
    if [ $counter == 0 ]; then
        printf "${RED}Select one main file${EC}\n"; user_input
    elif [ $counter -gt 1 ]; then
        printf "${RED}You have selected $counter main files, only select one${EC}\n"; user_input
    else
        # saving the command in history variable
        history -s "${char_input[@]}"; HISTCONTROL=ignoredups:erasedups
        # saving this command so user just enters "Enter" to execute previous command
        prev_char_input=("${char_input[@]}")

        evaluate_command "${char_input[@]}"
    fi
}
function prev_cmnd()
{
    if [ ${#prev_char_input[@]} -gt 0 ]; then
        # displays the previous command
        printf "${RML}Enter: ${BOLD}${DIM}${YELW}"; echo -n ${prev_char_input[@]}; printf "${EC}\n"
        # sends the command the evaluate_command function skipping the 'validate_each_character' & "check_for_main"
        evaluate_command "${prev_char_input[@]}"
    else
        # if the previous command is empty
        printf "${RED}No previous command${EC}\n"; user_input
    fi
}
function print_asm_files()
{
    # grabs the number of .asm file in current directory
    num_asm_files=$(ls | grep '\b.asm\b' | wc -l)

    # If there are no .asm files in directory
    if [ $num_asm_files == 0 ]; then
        printf "${BOLD}${RED}No .asm files here!${EC}\n"; exit 0
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
    # grabbing each character from user input and putting them into array
    echo; read -r -e -p $'Enter: \e[1m\e[33m' -a char_input; printf "${EC}"    

    sz_of_input=${#char_input[@]}

    # user is able to run the previous command by leaving the prompt blank
    if   [ $sz_of_input == 0 ]; then
        prev_cmnd
    # single input commands that clear screen, clear history, and show history
    elif [ $sz_of_input == 1 ]; then 
        local bool=false
        if   [ "${char_input[0]}" == 'c'  ]; then clear; bool=true;
        elif [ "${char_input[0]}" == 'ch' ]; then history -c; printf "${RED}Cleared input history${EC}\n\n"; bool=true; 
        elif [ "${char_input[0]}" == 'h'  ]; then history; echo; bool=true; fi

        if [ $bool = true ]; then print_asm_files; user_input; else validate_each_character; fi
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

    # if main file is found then set that name to be the executable
    if [ $check_for_start == 2 ]; then 
        main_file=$file_name
        link_cmd+=" '$main_file'.out"
    fi 

    # this checks if the obj file was created, o_file_created is set to 1 if so
    if [ "$file_name" == "$library_location" ]; then
        o_file_created=$(ls "${library_location%/*}" | grep "\b${library_location##*/}.o\b" | wc -l)
    else 
        o_file_created=$(ls | grep "\b$file_name.o\b" | wc -l)
    fi

    # if obj files was created then increment num_obj_files
    if [ $o_file_created == 1 ]; then ((num_obj_files++)); fi

    # this determines the string on the linking command
    if [ $check_for_start == 2 ]; then 
        link_cmd+=" '$file_name'.o"
    else
        link_cmd_other+=" '$file_name'.o"
    fi
}

function remove_obj_files()
{
    # removes the obj files selected from user after execution or debugging
    for ((i = 1 ; i < ${#char_input[@]} ; i++)); do
        if [[ ${char_input[$i]} =~ ^[0-9]+$ ]]; then

            local int=${char_input[$i]}

            local obj_file=$(ls | grep "\b${asm_file[$int-1]}.o\b" | wc -l)
            if [ $obj_file == 1 ]; then rm "${asm_file[$int-1]}.o"; fi
        fi
    done

    # removes any obj file from library dir
    local num_obj_files=$(ls $lib_dir | grep "\b.o\b" | wc -l)
    if [ $num_obj_files -gt 0 ]; then rm $lib_dir/*.o; fi
}

function remove_previous_out_file()
{
    # code below deletes the previous main .out file if there was one created
    local out_file=$(ls | grep "\b$main_file.out\b" | wc -l) 
    if [ $out_file == 1 ]; then rm "$main_file.out"; fi
}

function find_library()
{
    # getting the number of libraries declared by user in main
    lib_count=$(cat "$main_file.asm" | grep -w "lib:" | wc -l)

    if [ $lib_count -gt 0 ]; then 
        for ((i = 1 ; i <= $lib_count ; i++))
        do 
            # grab the name of the library file
            lib_name=$(cat "$main_file.asm" | grep -w "lib:" | grep "lib:" -n | grep $i | awk '{print $3}')
            # get the path to the file
            library_location=$(find $lib_dir -type f -name $lib_name -not -path "$HOME/.local/share/Trash/*" | cut -f 1 -d '.')
            # if file is not found in directory declared then throw error message
            if [ "$library_location" == "" ]; then
                printf "${RED}'$lib_name' was not found ${EC}\n"
            else 
                create_linking_command "$library_location"
            fi
        done
    fi 
}

function evaluate_command()
{
    # passing in the array from parameter
    char_input=("$@")

    # creating a string for the link command
    link_cmd="ld -m elf_i386 -o"
    link_cmd_other=""
    # keeping track of the number of obj files created
    num_obj_files=0

    # going through each character after the first in order to create the linking command
    for ((i = 1 ; i < ${#char_input[@]} ; i++)); do

        if [[ ${char_input[$i]} =~ ^[0-9]+$ ]]; then 
            int=${char_input[$i]}
            create_linking_command "${asm_file[$int-1]}"
        fi

    done

    find_library
}

function execute_debug()
{
    # compares the number of obj files created with the size of the command minus one
    if [ $num_obj_files == $((${#char_input[@]}-1 + $lib_count)) ]; then 

        # executes the linking command with the string created in "evaluate command" function
        eval "$link_cmd$link_cmd_other"
        # determines if .out file was created
        local out_file=$(ls | grep "\b$main_file.out\b" | wc -l)

        if [ $out_file == 1 ]; then 
        
            # if user chose 'e' then execute the main .out file
            if [ ${char_input[0]} == 'e' ]; then

                eval "./'$main_file'.out"; printf "Exited ${GRN}$main_file.out${EC}\n"

            # otherwise debug the main .out file
            else
                eval "gdb --quiet '$main_file'.out"
            fi
        fi
    fi

    # user decides whether or not they want to keep the obj and .out files
    if [ $keep_obj_files = false ]; then remove_obj_files; fi
    if [ $keep_out_files = false ]; then remove_previous_out_file; fi
}

function exit_script() 
{    
    local num=$num_asm_files

    # setting the amount of text to be removed
    if [ $display_how_to_exit = true ]; then num=$((num+4)); else num=$((num+2)); fi

    # This will remove the text from output (the enter prompt and list of files) 
    echo; for i in $(seq 1 $num); do printf ${RML}; done

    # this will write the user's input into history
    if [ $create_input_history = true ]; then history -w; fi

    exit 0
}

### MAIN ###

# "trap" catches signals and "Ctrl + C" signals SIGINT 
trap exit_script SIGINT

# this will read user's input history which enables user to use the up/down array keys
if [ $create_input_history = true ]; then HISTCONTROL=erasedups; history -r; fi 

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