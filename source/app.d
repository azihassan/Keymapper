import std.stdio : File;
import std.algorithm : map, splitter;
import std.exception : enforce;
import std.datetime;
import std.file : exists, thisExePath, getcwd;
import std.string;
import std.format : formattedRead;
import std.array : array;
import std.conv : to;
import std.path : buildPath;
import winapi;

debug
{
	import std.stdio: writefln, writeln;
}

uint[uint] keyMaps;
int lastKeyPressed;
TickDuration lastTimePressed;
uint interval = 150; //milliseconds
StopWatch sw;

int main(string[] args)
{
	if(args.length > 1)
		interval = args[1].to!uint;
	ensurePersistence();
	auto keyFile = buildPath(getcwd(), "keys.txt");
	if(keyFile.exists)
	{
		foreach(line; File(keyFile).byLine)
		{
			uint key;
			uint val;
			auto parts = line.splitter(":").map!strip.array;
			if(parts[0].startsWith("VK_"))
				key = parts[0].to!Keys;
			else
				parts[0].formattedRead("0x%x", &key);
			if(parts[1].startsWith("VK_"))
				val = parts[1].chomp(",").to!Keys;
			else
				parts[1].formattedRead("0x%x,", &val);
			keyMaps[key] = val;
		}
	}
	sw.start();
	auto hook = SetWindowsHookEx(WH_KEYBOARD_LL, cast(HOOKPROC) &kbdHook, null, 0);
	enforce(hook, "Failed to register keyboard hook : " ~ GetLastError().to!string);
	scope(exit)
	{
		UnhookWindowsHookEx(hook);
		sw.stop();
	}
	MSG msg;
	while(GetMessage(&msg, null, 0, 0) != 0)
	{
		TranslateMessage(&msg);
		DispatchMessage(&msg);
	}
	return 0;
}

extern(Windows) LRESULT kbdHook(int nCode, WPARAM wParam, LPARAM lParam)
{
	auto hookStruct = cast(KBDLLHOOKSTRUCT *) lParam;
	if(nCode == 0)
	{
		auto pressed = hookStruct.vkCode;
		debug
		{
			try
			{
				writeln("Pressed : ", pressed.to!Keys);
			}
			catch(Exception)
			{
				writefln("Pressed : %x", pressed);
			}
		}
		if(wParam == WM_KEYDOWN)
		{
			lastKeyPressed = pressed;
			lastTimePressed = sw.peek();
		}
		else if(wParam == WM_KEYUP)
		{
			debug
			{
				writeln("\t", pressed, " == ", lastKeyPressed, " && ", keyMaps.get(pressed, 0), " != ", 0, " : ", pressed == lastKeyPressed && keyMaps.get(pressed, 0) != 0);
			}
			if(pressed == lastKeyPressed && keyMaps.get(pressed, 0) != 0)
			{
				debug
				{
					writeln("\t", lastTimePressed.msecs + interval, " < ", sw.peek().msecs);
				}
				if(lastTimePressed.msecs + interval < sw.peek().msecs)
				{
					lastKeyPressed = 0;
					sendKey(VK_BACK);
					sendKey(keyMaps[pressed]);
				}
			}
		}
	}

	return CallNextHookEx(null, nCode, wParam, lParam);
}

void sendKey(uint keyCode, uint scanCode = 0)
{
	keybd_event(cast(ubyte) keyCode, cast(ubyte) scanCode, 0, 0);
	keybd_event(cast(ubyte) keyCode, cast(ubyte) scanCode, KEYEVENTF_KEYUP, 0);
}

void ensurePersistence()
{
	import std.windows.registry;
	auto key = Registry.currentUser.getKey(`Software\Microsoft\Windows\CurrentVersion\Run`, REGSAM.KEY_ALL_ACCESS);
	
	try
	{
		key.getValue("Keymapper");
	}
	catch(RegistryException e)
	{
		key.setValue("Keymapper", thisExePath);
	}
}

