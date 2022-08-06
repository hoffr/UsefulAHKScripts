/*
; auto dismiss file extension change dialog in windows explorer when renaming
SetTitleMatchMode,3
SetControlDelay,-1
SetBatchLines,-1
settimer,IsExplorerActive,200
loop {
	explorerHwnd:=WinActive("ahk_class CabinetWClass")
	sleep,200
	
	
	
	
		{
		dialogHwnd := WinActive("Rename ahk_class #32770")
		if (dialogHwnd && dialogHwnd != wrongdialogHwnd) {
			SoundBeep,0,0 ; cut off notif sound by playing silence - earlier/aggressive placement in script
			ControlGetText,ctrlText,Button1
			if (ctrlText = "&Yes") { ; be somewhat sure it's the right window
				;SoundBeep,0,0 ; slightly late placement - ControlGetText causes few ms delay
				ControlClick,Button1,,,,,NA
			} else
				wrongdialogHwnd := dialogHwnd ; don't recheck next time
		}
		sleep,15
	}
	sleep,200
}
*/
;;;;

; auto dismiss file extension change dialog in windows explorer when renaming
SetTitleMatchMode,3
SetControlDelay,-1
SetBatchLines,-1
loop {
	if (WinActive("Rename ahk_class #32770 ahk_exe explorer.exe")) { ; faster response than WinWaitActive & same cpu usage
		SoundBeep,0,0 ; cut off notif sound by playing silence
		ControlClick,Button1
		WinWaitNotActive
	}
	sleep,15
}
