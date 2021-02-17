; -------------
; youtube_multimedia_controls.ahk by github:hoffersrc / reddit:Splongus
; Purpose: Quickly pause/resume YouTube from any window or browser tab without disrupting too much of your experience.
; To pause/resume YouTube, hold your keyboard's media play/pause button for 1/3 of a second.
; ---
; Limitations:
; 1. Traditional media pause/resume will now be on-release instead of on-press.
; 2. Only the first YouTube tab the script detects will be paused/resumed. To detect a YouTube tab, the script traverses tabs from left-right
;    starting with the active tab, and wraps around until it reaches the tab it started on unless it finds a YouTube tab before then.


; -------------
; EZ VARIABLES:

; known to be compatible with firefox & chrome
browsername := "firefox.exe"

; time in ms to wait for browser to be 'usable' upon initial failure
; raise this by increments of 500 if youtube doesn't play/pause properly when alt-tabbing from a fullscreen app
reattemptdelay := 500


; -------------

#SingleInstance,Force
#KeyHistory 0
SetBatchLines,-1
return


; ---

Media_Play_Pause Up:: ; media btn may be 'artificial': https://www.autohotkey.com/boards/viewtopic.php?t=78410
Media_Next Up::
Media_Prev Up::
	mediaButtonIsDown := 0
return



; ---

Media_Play_Pause::
	MediaAction("PlayPause")
return

Media_Next::
	MediaAction("Next")
return

Media_Prev::
	MediaAction("Prev")
return


; ---

MediaAction(button) {
	
	global
	
	mediaButtonIsDown := 1
	
	ts1 := A_TickCount
	pauseYouTube := 0
	while (mediaButtonIsDown) {
		if (A_TickCount - ts1 > 330) {
			pauseYouTube := 1
			break
		}
		sleep,1
	}
	
	if (!pauseYouTube) {
		switch (button) {
			case "PlayPause": Send,{Media_Play_Pause}
			case "Next": Send,{Media_Next}
			case "Prev": Send,{Media_Prev}
		}
		return
	}
	
	SetTitleMatchMode,2
	
	if (!WinExist("ahk_exe" browsername)) {
		return
	}
	
	prevhwnd := ""
	if (!WinActive("ahk_exe" browsername)) {
		WinGet,prevhwnd,id,A
		WinActivate,% "ahk_exe" browsername
		WinWaitActive,% "ahk_exe" browsername,,3
		if (ErrorLevel) {
			return ; somefins wrong
		}
	}
	
	tab2 := tab1 := "ERROR_UNSET"
	tabCycles := noYouTube := tab1match := 0
	while (!WinActive("- YouTube")) {
		
		if (A_Index = 1) {
			WinGetTitle,tab1,A
		}
		
		if (A_Index = 2) {
			WinGetTitle,tab2,A
			
			; browser prob hasn't loaded in yet: only do one attempt to re-sync, in case there are 2 identical tabs side-by-side
			if (tab2 = tab1) {
				sleep,% reattemptdelay
				Send,^{PgDn}
				++tabCycles
				sleep,20
			}
		}
		
		SetTitleMatchMode,3
		if (A_Index != 1 && WinActive(tab1)) { ; if it appears that we've wrapped around completely, but not sure yet
			tab1match := 1
		}
		if ((A_Index != 2 && WinActive(tab2)) && tab1match) { ; flimsy confirmation by seeing if the two adjacent tab titles match the initial 2
			noYouTube := 1
			break ; youtube tab is not present, give up
		}
		SetTitleMatchMode,2
		
		Send,^{PgDn}
		++tabCycles
		sleep,20
		
	}
	
	if (!noYouTube) {
		switch (button) {
			case "PlayPause": Send,k
			case "Next": Send,k{l 2}k ; user may be more distracted while in another window, so larger rewind
			case "Prev": Send,k{j 2}k ; keeping it consistent ("k" before/after to avoid weird audio)
		}
	}
	
	Send,% "^{PgUp " tabCycles "}"
	if (prevhwnd) {
		WinActivate,% "ahk_id" prevhwnd
	}
	
}
