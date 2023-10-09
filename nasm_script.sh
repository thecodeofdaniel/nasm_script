#!/bin/bash

# Grabs the $PWD of where the script is being run
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


# Grabs the library directory from "lib_dir.txt"
LIB_DIR=$(head -n 1 $SCRIPT_DIR/lib_dir.txt | grep -oE '^\S+')

# Set to true if you want to keep .o/.out files
keep_obj_files=false
keep_out_files=false


# Colors/text format
END="\e[0m"
BLD="\e[1m"
DIM="\e[2m"
RED="\e[31m"
GRN="\e[32m"
YLW="\e[33m"
BLU="\e[34m"

# Command to build object files
BUILD_CMND="nasm -f elf"

function _remove_obj_files()
{
    if find . -type f -name "*.o" | grep -q .; then
        rm *.o
    fi
}

function _remove_lib_obj_files()
{
    if find $LIB_DIR -type f -name "*.o" | grep -q .; then
        rm $LIB_DIR/*.o
    fi
}

function _remove_out_file()
{
    if find . -type f -name "*.out" | grep -q .; then
        rm *.out
    fi
}

function _list()
{
    # Grab number of .asm files
    num_asm_files=$(ls | grep "\b.asm\b" | wc -l)

    # Exit if no .asm files exist
    if [ $num_asm_files == 0 ]; then
        printf "${BLD}${RED}No .asm files here!${END}\n"
    else
        # Display how to exit script
        printf "${DIM}Exit script with: ${BLD}${YLW}<Ctrl> + C${END}\n\n"

        # Add file names to array and output them
        for ((i = 0 ; i < $num_asm_files ; i++)); do
            asm_file[$i]=$(ls | grep "\b.asm\b" | grep .asm -n | grep "$(($i+1)):")
            asm_file[$i]=${asm_file[$i]##*:};
            asm_file[$i]=${asm_file[$i]%.*}
            printf "${BLD}${BLU}$(($i+1)).${END} ${asm_file[$i]}.asm\n"
        done
    fi
}

function _validate()
{
    local errors=0

    # check first character
    if [ "${cmnd[0]}" != 'e' ] && [ "${cmnd[0]}" != 'd' ]; then
        printf "${RED}'e' or 'd' should be the first character${END}\n"; ((errors++))
    fi

    # check rest of characters
    for ((i = 1 ; i < ${#cmnd[@]} ; i++))
    do
        if [[ ${cmnd[$i]} =~ ^[0-9]+$ ]]; then
            # if integer is not on the list
            if [ ${cmnd[$i]} == 0 ] || [ ${cmnd[$i]} -gt $num_asm_files ]; then
                printf "${RED}'${cmnd[$i]}' is not on the list${END}\n"; ((errors++))
            fi
        else
            # if character is not an integer
            printf "${RED}'${cmnd[$i]}' is not a valid option at position $(($i+1))${END}\n"; ((errors++))
        fi
    done

    # add all files listed into command if 'e' or 'd' is only entered
    if [ ${#cmnd[@]} == 1 ] && [ $errors == 0 ]; then
        for ((i = 0 ; i < $num_asm_files ; i++)); do
            cmnd[(${#cmnd[@]}+$i)]=$(($i+1))
        done
    fi

    if [ $errors == 0 ]; then _evaluate "${cmnd[@]}"; fi
}

function _prev_cmnd()
{
    # check if previous command exists
    if [ ${#prev_cmnd[@]} != 0 ]; then
        # output the previous command
        printf "\e[1A\e[KEnter: ${BLD}${DIM}${YLW}"; echo -n ${prev_cmnd[@]}; printf "${END}\n"
        _evaluate "${prev_cmnd[@]}"
    else
        printf "${RED}No previous command${END}\n"
    fi
}

function _input_cmnd()
{
    # grab user input
    read -r -e -p $'\nEnter: \e[1m\e[33m' -a cmnd; printf "${END}"

    # use previous command
    if   [ ${#cmnd[@]} == 0 ]; then
        _prev_cmnd
    # use clear command
    elif [ ${#cmnd[@]} == 1 ] && [ "${cmnd[0]}" == 'c' ]; then
        clear; _list;
    else
        _validate
    fi
}

function _compile_link()
{
    # pass in name of file from argument
    local file=$1

    # create object file
    if [ "${cmnd[0]}" == 'e' ]; then
        $BUILD_CMND "$file.asm"
    else
        $BUILD_CMND -g "$file.asm"
    fi

    # check if object file was created
    if [ "$file" == "$lib_path" ]; then
        local obj_file=$(ls "${lib_path%/*}" | grep "\b${lib_path##*/}.o\b" | wc -l)
    else
        local obj_file=$(ls | grep "\b$file.o\b" | wc -l)
    fi

    # increment if object file was created
    if [ $obj_file == 1 ]; then ((num_obj_files++)); fi

    # add file to linking command
    if [ "$file" == "$main_file" ]; then
        link_cmnd_1+=" '$file'.o"
    else
        link_cmnd_2+=" '$file'.o"
    fi
}

function _search_libraries()
{
    # get number of libraries declared in main
    lib_count=$(cat "$main_file.asm" | grep -w "lib:" | wc -l)

    if [ $lib_count -gt 0 ]; then
        for ((i = 1 ; i <= $lib_count ; i++))
        do
            # grab name of file and see if it exists
            local lib=$(cat "$main_file.asm" | grep -w "lib:" | grep "lib:" -n | grep $i | awk '{print $3}')
            lib_path=$(find $LIB_DIR -type f -name $lib | cut -f 1 -d '.')
            # if file is not found
            if [ "$lib_path" == "" ]; then
                printf "${RED}\"$lib\" was not found ${END}\n"
            else
                _compile_link "$lib_path"
            fi
        done
    fi
}

function _evaluate()
{
    # pass in the cmnd (array)
    cmnd=("$@")

    # counter for main and object files
    local main_counter=0
    num_obj_files=0

    # string for linking command
    link_cmnd_1="ld -m elf_i386 -o"
    link_cmnd_2=""

    # go through each file
    for ((i = 1 ; i < ${#cmnd[@]} ; i++))
    do
        local int=${cmnd[$i]}

        # check file for main
        local check_for_start=$(cat "${asm_file[$int-1]}.asm" | grep "_start" | wc -l)
        if [ $check_for_start == 2 ]; then
            ((main_counter++))

            if [ $main_counter -gt 1 ]; then break; fi

            # set that file as main
            main_file=${asm_file[$int-1]}
            link_cmnd_1+=" '$main_file'.out"
        fi

        # compile file
        _compile_link "${asm_file[$int-1]}"
    done

    # command should only include one main file
    if [ $main_counter != 1 ]; then
        printf "${RED}Include (only) one main file${END}\n"; _remove_obj_files
    else
        # save command into history
        history -s "${cmnd[@]}"; HISTCONTROL=ignoredups:erasedups
        prev_cmnd=("${cmnd[@]}")

        _search_libraries
        _execute_debug
    fi
}

function _execute_debug()
{
    # compare number of object files created and number of files declared
    if [ $num_obj_files == $((${#cmnd[@]}-1 + $lib_count)) ]; then

        # execute the linking command
        eval "$link_cmnd_1$link_cmnd_2"

        # check if .out file was created
        local out_file=$(ls | grep "\b$main_file.out\b" | wc -l)

        if [ $out_file == 1 ]; then
            if [ ${cmnd[0]} == 'e' ]; then
                eval "./'$main_file'.out";
                printf "Exited ${GRN}$main_file.out${END}\n"
            else
                eval "gdb --quiet '$main_file'.out"
            fi
        fi
    fi

    # remove all .o/.out files if user chooses so
    if [ $keep_obj_files = false ]; then _remove_obj_files; _remove_lib_obj_files; fi
    if [ $keep_out_files = false ]; then _remove_out_file; fi
}

trap exit 0 SIGINT

function _main()
{
    _input_cmnd
    _main
}

_list; _main
