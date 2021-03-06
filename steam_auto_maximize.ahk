; steam_auto_maximize.ahk by github:hoffr / reddit:Splongus
; Purpose: Auto-maximize Steam user interface, so whenever I use its scrollbar it doesn't just try to annoyingly resize the window
; This is designed to not auto-maximize the window if the user has intentionally windowed it, aka to be as unintrustive as possible.
; eg. User launches Steam and once the main library window pops up it is maximized. User or a low-res game de-maximizes/resizes the window, but this script does nothing until Steam is restarted.

loop {
	Process,Exist,% "steam.exe"
	if (ErrorLevel) {
		while !(WinActive("ahk_exe steam.exe") && steamHwnd := WinActive("ahk_class vguiPopupWindow")) { ; proper window identification #1
			sleep,500
		}
		WinGetText,steamText,% "ahk_id" steamHwnd
		if (InStr(steamText,"Chrome Legacy Window")) { ; #2: works cuz it applies to the main ui, but not launcher ui or tray ui
			WinMaximize,% "ahk_id" steamHwnd
			loop { ; don't maximize again until steam is restarted (if ever)
				Process,Exist,% "steam.exe"
				sleep,2000
			} until (!ErrorLevel)
		}
	}
	sleep,2000
}
