; Automatically save every newly downloaded spray to an external folder before their deletion.
; v3 must check for new sprays every few seconds while the game is running rather than copying all on game exit.

#SingleInstance,Force
SetTitleMatchMode,2

; wait for game to run so we can get its full path
while !(hwndTF2:=WinExist("Team Fortress 2 ahk_exe hl2.exe"))
	sleep,10000

WinGet,pathTF2,ProcessPath,% "ahk_id" hwndTF2
SplitPath,% pathTF2,,pathTF2 ; exclude exe name from path

loop
{
	while (WinExist("Team Fortress 2 ahk_exe hl2.exe"))
	{
		loop,files,% pathTF2 "\tf\materials\temp\*"
		{
			FileCreateDir,% pathTF2 "\tf\materials\copiedspraydownloads"
			FileCopy,% A_LoopFileLongPath,% pathTF2 "\tf\materials\copiedspraydownloads",0
			sleep,20
		}
		sleep,2000
	}
		
	; wait for tf2 to run again
	while !(WinExist("Team Fortress 2 ahk_exe hl2.exe"))
		sleep,10000
}
