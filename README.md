# Keymapper
A small utility that allows a keyboard key to produce another value if pressed for a certain amount of time.

This was inspired by the excelent DevKeyboard project : https://github.com/babin101/DevKeyboard

I wrote this utility as a temporary solution to a problem I've been having with my keyboard these past few days. Some keys would stop working for no apparent reason : TAB, S, 2 and a couple others. This program maps those keys to other buttons that actually work, allowing me to type S by maintaining Z pressed for a short amount of time : 150 milliseconds to be precise, but you can change that value by passing it as a first argument to the program.

I used DevKeyboard for a while but ended up deciding to just write my own program. The code is based on a keylogger I have been writing a while ago (just an experiment, nothing naughty), as it uses similar techniques to intercept the keys that are pressed. Because of this, this program may or may not be flagged by your antivirus.

The key mapping is supposed to be put in the keys.txt file. Recompiling would result into those keys being hard-coded into the program, thus making it work without the text file. But it is also possible to compile it with an empty keys.txt file and place the keys in it afterwards, and it will still work as expected.

The only reason why I added that feature (compile-time loading of keys) in the first place was because it was easier to parse that way.

## About the Win32 API

Initially I wrote this program with the help of [these bindings](https://github.com/Diggsey/druntime-win32), but since I couldn't find said bindings on code.dlang.org, I simply put the functions/structs/enums I used inside a separate winapi.d file and imported that instead.

## Usage

`keymapper <interval in milliseconds>`

The program runs in the background, you can close it by terminating the corresponding process in the Task Manager.
