; ahk v1.1
 
 #NoTrayIcon
#Persistent
DetectHiddenWindows,On
Menu,Tray,Click,1
Menu,Tray,Tip,% "Click to restore Chatterino"
Menu,Tray,NoStandard
Menu,Tray,Add,Restore,RestoreLabel
Menu,Tray,Add,Exit tray script,ExitLabel
Menu,Tray,Default,Restore

FakeReload:
; wait for window to exist
index:=0 ; indicator for if the loop ran at all
while (!hwnd:=WinExist("ahk_exe chatterino.exe"))
{
	index:=A_Index
	sleep,500
}

WinGet,procPath,ProcessPath,% "ahk_id " hwnd
Menu,Tray,Icon,% procPath,1,1

; if chatterino is open and minimized before running the script, WinGet will report 0 for minmax state
; not sure exactly why, must have to do with window detection
if (index = 0) ; if chatterino was open before script started
{
	msgbox,1,% "Restart Chatterino?",% "Chatterino must be restarted for script to take effect.`nPress OK to automatically restart Chatterino, or Cancel to exit the script"
	ifmsgbox,OK
	{
		loop {
			Process,Close,chatterino.exe
		} until !ErrorLevel
		while (WinExist("ahk_id " hwnd))
			sleep,100
		run,% procPath
		; effectively a faster alternative to a script reload to make sure we catch the correct chatterino handle upon its opening
		goto,FakeReload
	}
	else
	{
		exitapp
	}
}



loop
{
	; wait for window to minimize
	loop {
		sleep,500
		if WinExist("ahk_id " hwnd) ; make sure still exists
			WinGet,minmax,MinMax,% "ahk_id " hwnd
		else
			reload
	} until (minmax = -1)
	minimized:=True

	WinHide,% "ahk_id " hwnd
	Menu,Tray,Icon

	while minimized
	{
		if !WinExist("ahk_id " hwnd) ; make sure still exists
			reload
		sleep,500
	}
}


ExitLabel:
	WinShow,% "ahk_id " hwnd
	WinRestore,% "ahk_id " hwnd
exitapp

RestoreLabel:
	Menu,Tray,NoIcon
	WinShow,% "ahk_id " hwnd
	WinRestore,% "ahk_id " hwnd
	minimized:=False
return
