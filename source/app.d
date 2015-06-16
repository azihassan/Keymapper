import std.stdio : writeln, File;
import std.exception : enforce;
import std.datetime;
import std.file : exists;
import std.string : indexOf;
import std.format : formattedRead;
import std.conv;
import winapi;

uint[uint] keyMaps;
int lastKeyPressed;
TickDuration lastTimePressed;
enum interval = 150; //milliseconds
StopWatch sw;

int main(string[] args)
{
	sw.start();
	mixin("keyMaps = [" ~ import("keys.txt") ~ "];");
	foreach(line; File("keys.txt").byLine)
	{
		uint key;
		uint val;
		writeln(line);
		if(line.indexOf("VK_") == -1)
		{
			line.formattedRead("0x%x: 0x%x,", &key, &val);
		}
		else
		{
			string vk_;
			line.formattedRead("0x%x: %s,", &key, &vk_);
			val = vk_.to!Keys;
		}
		keyMaps[key] = val;
	}
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
		if(wParam == WM_KEYDOWN)
		{
			lastKeyPressed = pressed;
			lastTimePressed = sw.peek();
		}
		else if(wParam == WM_KEYUP)
		{
			if(pressed == lastKeyPressed && keyMaps.get(pressed, 0) != 0)
			{
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

