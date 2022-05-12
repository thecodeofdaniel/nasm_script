# How to run script:

Once you've downloaded the script, go to your Downloads directory

```
$ cd ~/Downloads
```
Run this command to list all files with their file permissions
```
$ ls -l
```
You'll see this line

![non_exe_script](https://user-images.githubusercontent.com/100104016/168086026-d7bfea17-8389-4d54-acb5-988b20a27ced.png)

Run this command to change the script.sh file permissions
```
$ chmod +x nasm_script.sh
```
Run this command again
```
$ ls -l
```
You'll now see this line

![exe_script](https://user-images.githubusercontent.com/100104016/168086118-0ac63b7e-0f16-4b09-882b-11d4980c2259.png)

This file is now executable (note: the file will be highlighted in green to let you know also)

Now move this file to the directory your working in

### Example

```
$ mv script.sh ~/Desktop/csci150_AssemblyLanguage/labs/lab6b
```
### Tip: Use `tab` to autocomplete folder names

Once you've done so, run the script

```
$ ./script.sh
```
# Guide:

When you run the script you will be prompted with

```
Exit the script with: Ctrl + C

1: asm_file1.asm
2: asm_file2.asm
3: asm_file3.asm

Enter: 
```
You only have to enter one command for this script

### Example

```
Enter: e 1 2
```
or 
```
Enter: d 1 2
```

### Explanation: 

`
e = execute
`
| 
`
d = debug
`

`
1 = the first file listed in prompt
`

`
2 = the second file listed in prompt
`

The order in which you put the files does not matter, so I could've instead put 

```
Enter: e 2 1
```

However, your first character should always be: `e` or `d`


Another character that is optional in your command is: `l`

`
l = the 'l'ibrary file located in some other directory
`

Rather than dragging your library file into the directory your working in, you can leave it someplace else and your program will still be able to run

More info about the `l` command below 

### Shortcut:

Entering a command with no selected files from the list will assume that you want all files within the current directory to be executed or debugged

#### Example
```
Enter: e
```
is the same as 

```
Enter: e 1 2 3
```
The same goes for debugging: `d` 

## Using the ``l`` command

If you ever use the `l` command you have two options: 

* 1: Give the location of your library file

* 2: Let the script find your library file

### Option 1:

Make sure to give its location along with it's file name with the .asm extension in ``line 3`` of the script 

#### Example

```
3   library_location="$HOME/Desktop/csci150_AssemblyLanguage/z_library/library.asm"
```

### Option 2:

Set ``line 6`` to true 

```
6   let_script_find_library=true
```
Give the name of your library file on ``line 7``

```
7   lib_name="library.asm"
```

Check to see if any other files in home your directory have the same name, there should only be 1 output

```
$ find $HOME -type f -name <insert_library_name.asm> -not -path "./.local/share/Trash/*"
```

If there's more than one output, rename your library with a unique one such as

```
7   lib_name="library_for_script.asm"
```

# Other Commands: 

These commands are not required to run your program but they are convenient 

`
<empty> = execute/debug the last acceptable command of that session
`

:arrow_up_down: keys
`
= go through user input history
`

`
h = display user input history
`

`
c = clear screen
`

`
ch = clear user input history
`



# Video Examples: 

https://user-images.githubusercontent.com/100104016/168119627-6143bba3-99f0-44da-a8b0-796f1aaf9726.mp4


https://user-images.githubusercontent.com/100104016/168119679-3532adcb-e064-4fcb-8123-386a6ea7d6d8.mp4


https://user-images.githubusercontent.com/100104016/168119711-e74d171f-24da-4bbf-9c98-3e4a03a2198f.mp4

