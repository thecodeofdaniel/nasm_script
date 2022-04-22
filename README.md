# How to run script:

Once you've downloaded the script, go to your Downloads directory

```
$ cd ~/Downloads
```
Run this command to list all files with their file permissions
```
$ ls -lAh
```
You'll see this line

![Screenshot from 2022-04-15 08-25-33](https://user-images.githubusercontent.com/100104016/163589346-6ca95d2a-e212-4c0c-a65f-968d69fb9cdd.png)

Run this command to change the script.sh file permissions
```
$ chmod +x script.sh
```
Run this command again
```
$ ls -lAh
```
You'll now see this line

![Screenshot from 2022-04-15 08-29-31](https://user-images.githubusercontent.com/100104016/163590031-4fd33693-7d31-4dda-8b70-f1b11616bd28.png)

r = read | w = write | x = execute

This file is now executable (note: the file will be highlighted in green to let you know also)

Now move this file to the directory your working in

Once you've done so, run the script

```
$ ./script.sh
```
# Guide:

When you run the script you will be prompted with

```
You can always exit the script with: Ctrl + C

1: asm_file1.asm
2: asm_file2.asm
3: asm_file3.asm

Enter: 
```
You only have to enter one command for this script

This command should only receive characters with space in between each one

### Example

```
Enter: e 1 2
```
### Explanation: 

`
e = execute the following files...
`

`
1 = the first file listed in prompt
`

`
2 = the second file listed in prompt
`

The order in which you put the integers does not matter, so I could've instead put 

```
Enter: e 2 1
```

Any other characters do matter however, these are: `e` `d` `a` `l`

`
e = execute the following files...
`

`
d = debug the following files...
`

`
a = include 'a'll files listed in prompt
`

`
l = include 'l'ibrary file located in some other directory
`

### Order of characters: 


Your first character should always be: `e` or `d`

The next character(s) should be an integer(s), however if you would like to include all files listed: `a`

The last character is not necessary but if you would like to include your library located in some other directory with all of your procedures: `l`

#### Note:

If at anytime you enter the command in the wrong order, you will be prompted with what you should enter colored in red and be able to try again :)

## Using the ``l`` command

If you ever use the `l` command

Make sure to give its location along with it's file name with the .asm extension in ``line 3`` of the script 

### Example

```
3   library_location="/home/$(whoami)/Desktop/csci150_AssemblyLanguage/library/library.asm"
```

#### Note: This command prints the effective username of the current user

```
$ whoami
```

# Video Examples: 

https://user-images.githubusercontent.com/100104016/164744995-72a42850-883f-4476-9bea-10f87e143857.mp4


https://user-images.githubusercontent.com/100104016/164745022-25f55703-3979-41f0-8a92-609bef40de91.mp4
