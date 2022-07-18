#!/bin/bash

lib_dir="$HOME/PATH/TO/LIBRARY/FOLDER"

# set to true if you want to save your inputs even after exiting script
create_input_history=false
# set to true to both if you want to keep object and .out files
keep_obj_files=false
keep_out_files=false

# colors/text format when outputting text
END="\e[0m"
BLD="\e[1m"
DIM="\e[2m"
RED="\e[31m"
GRN="\e[32m"
YLW="\e[33m"
BLU="\e[34m"

function remove_obj_files()
{
    # removes all obj files from current dir
    local num_obj_files=$(ls | grep "\b.o\b" | wc -l)
    if [ $num_obj_files -gt 0 ]; then rm *.o; fi

    # removes all obj files from library dir
    local num_obj_files=$(ls $lib_dir | grep "\b.o\b" | wc -l)
    if [ $num_obj_files -gt 0 ]; then rm $lib_dir/*.o; fi
}

function remove_out_file()
{
    # removes all .out files from dir
    local num_out_file=$(ls | grep "\b.out\b" | wc -l)
    if [ $num_out_file -gt 0 ]; then rm *.out; fi
}

function print_asm_files()
{
    # gets number of .asm files in current dir
    num_asm_files=$(ls | grep '\b.asm\b' | wc -l)

    # If there are NO .asm files in current dir
    if [ $num_asm_files == 0 ]; then
        printf "${BLD}${RED}No .asm files here!${END}\n"; exit 0
    fi

    # displays how to exit script
    printf "${DIM}Exit the script with: ${BLD}${YLW}Ctrl + C${END}\n\n"

    # puts names of .asm files in array and outputs to screen
    for ((i = 0 ; i < $num_asm_files ; i++)); do
        asm_file[$i]=$(ls | grep "\b.asm\b" | grep .asm -n | grep "$(($i+1)):")
        asm_file[$i]=${asm_file[$i]##*:}; asm_file[$i]=${asm_file[$i]%.*}
        printf "${BLD}${BLU}$(($i+1)).${END} ${asm_file[$i]}.asm\n"
    done
}

function validate_each_character()
{
    local errors=0

    # checks first character
    if [ "${char_input[0]}" != 'e' ] && [ "${char_input[0]}" != 'd' ]; then
        printf "${RED}'e' or 'd' should be the first character${END}\n"; ((errors++))
    fi

    # checks rest of characters (integers)
    for ((i = 1 ; i < $sz_of_input ; i++))
    do
        # checks if character is an integer
        if [[ ${char_input[$i]} =~ ^[0-9]+$ ]]; then
            # if integer is not on the list
            if [ ${char_input[$i]} == 0 ] || [ ${char_input[$i]} -gt $num_asm_files ]; then
                printf "${RED}'${char_input[$i]}' is not on the list${END}\n"; ((errors++))
            fi
        else
            printf "${RED}'${char_input[$i]}' is not a valid option at position $(($i+1))${END}\n"; ((errors++))
        fi
    done

    # if user enters only 'e' or 'd'
    if [ $sz_of_input == 1 ] && [ $errors == 0 ]; then
        # add all integers to command
        for ((i = 0 ; i < $num_asm_files ; i++)); do
            char_input[$sz_of_input+$i]=$(($i+1))
        done
    fi

    # if there are no errors then continue
    if [ $errors == 0 ]; then evaluate_command "${char_input[@]}"; fi
}

function prev_cmnd()
{
    # checks if previous command exists
    if [ ${#prev_char_input[@]} != 0 ]; then
        # outputs the previous command
        printf "\e[1A\e[KEnter: ${BLD}${DIM}${YLW}"; echo -n ${prev_char_input[@]}; printf "${END}\n"
        # skips the validate_each_character integer function
        evaluate_command "${prev_char_input[@]}"
    else
        printf "${RED}No previous command${END}\n"
    fi
}

function user_input()
{
    # grabbing user input
    read -r -e -p $'\nEnter: \e[1m\e[33m' -a char_input; printf "${END}"

    # num of characters from input
    local sz_of_input=${#char_input[@]}

    # if user leaves prompt empty
    if   [ $sz_of_input == 0 ]; then
        prev_cmnd
    # single input commands: clear, clear history, and show history
    elif [ $sz_of_input == 1 ]; then
        if   [ "${char_input[0]}" == 'c'  ]; then clear; print_asm_files;
        elif [ "${char_input[0]}" == 'ch' ]; then history -c; printf "${RED}Cleared input history${END}\n";
        elif [ "${char_input[0]}" == 'h'  ]; then history;
        else validate_each_character; fi
    else
        validate_each_character
    fi
}

function create_linking_command()
{
    # passing in name of file from parameter
    local file_name=$1

    # creating obj file
    if [ "${char_input[0]}" = 'e' ]; then
        nasm -f elf "$file_name.asm"
    else
        nasm -f elf -g "$file_name.asm"
    fi

    # checks if obj file was created
    if [ "$file_name" == "$library_location" ]; then
        o_file_created=$(ls "${library_location%/*}" | grep "\b${library_location##*/}.o\b" | wc -l)
    else
        o_file_created=$(ls | grep "\b$file_name.o\b" | wc -l)
    fi

    # if obj file was created then increment
    if [ $o_file_created == 1 ]; then ((num_obj_files++)); fi

    # sets up linking command string
    if [ "$file_name" == "$main_file" ]; then
        link_cmd+=" '$file_name'.o"
    else
        link_cmd_other+=" '$file_name'.o"
    fi
}

function look_for_libraries()
{
    # num of libraries declared in main
    lib_count=$(cat "$main_file.asm" | grep -w "lib:" | wc -l)

    if [ $lib_count -gt 0 ]; then
        for ((i = 1 ; i <= $lib_count ; i++))
        do
            # grabs name of the library file
            lib_name=$(cat "$main_file.asm" | grep -w "lib:" | grep "lib:" -n | grep $i | awk '{print $3}')
            # grabs path to the library file
            library_location=$(find $lib_dir -type f -name $lib_name -not -path "$HOME/.local/share/Trash/*" | cut -f 1 -d '.')
            # if file is not found then throw error message
            if [ "$library_location" == "" ]; then
                printf "${RED}'$lib_name' was not found ${END}\n"
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

    # link command string
    link_cmd="ld -m elf_i386 -o"
    link_cmd_other=""
    # counter for obj & main files
    num_obj_files=0
    main_counter=0

    # going through each integer
    for ((i = 1 ; i < ${#char_input[@]} ; i++))
    do
        int=${char_input[$i]}

        # check file for main
        local check_for_start=$(cat "${asm_file[$int-1]}.asm" | grep "_start" | wc -l)
        if [ $check_for_start == 2 ]; then
            main_counter=$((main_counter+1))
            main_file=${asm_file[$int-1]}
            link_cmd+=" '$main_file'.out"
        fi

        # if there's more than one main file in command then break
        if [ $main_counter -gt 1 ]; then break; fi

        create_linking_command "${asm_file[$int-1]}"
    done

    # command must include only one main file to continue
    if   [ $main_counter  == 0 ]; then
        printf "${RED}Include one main file${END}\n"; remove_obj_files
    elif [ $main_counter -gt 1 ]; then
        printf "${RED}Select only one main file${END}\n"; remove_obj_files
    else
        # saving command in hist var and in array
        history -s "${char_input[@]}"; HISTCONTROL=ignoredups:erasedups
        prev_char_input=("${char_input[@]}")
        # checks for libraries in main
        look_for_libraries
        # continues to the next function
        execute_debug
    fi
}

function execute_debug()
{
    # compares number of obj files created and number of files declared
    if [ $num_obj_files == $((${#char_input[@]}-1 + $lib_count)) ]; then

        # executes the linking command
        eval "$link_cmd$link_cmd_other"

        # checks if out file was created
        local out_file=$(ls | grep "\b$main_file.out\b" | wc -l)

        if [ $out_file == 1 ]; then
            # if user chose 'e' then execute the main file, otherwise debug
            if [ ${char_input[0]} == 'e' ]; then
                eval "./'$main_file'.out"; printf "Exited ${GRN}$main_file.out${END}\n"
            else
                eval "gdb --quiet '$main_file'.out"
            fi
        fi
    fi
}

function exit_script()
{
    # user decides whether or not they want to keep the obj and/or out files
    if [ $keep_obj_files = false ]; then remove_obj_files; fi
    if [ $keep_out_files = false ]; then remove_out_file; fi

    # write command into history
    if [ $create_input_history = true ]; then history -w; fi

    exit 0
}

# "trap" catches signals and "Ctrl + C" signals "SIGINT"
trap exit_script SIGINT

# read user's input history
if [ $create_input_history = true ]; then HISTCONTROL=erasedups; history -r; fi

# Allows script to loop until user exits
function main()
{
    user_input
    main
}

clear; print_asm_files; main