; -------------
; youtube_multimedia_controls.ahk by github:hoffersrc / reddit:Splongus
; Purpose: Quickly pause/play, next/prev, or rewind/fastforward YouTube from any window/browser tab without much disruption.
; To pause/play or rewind/fastforward YouTube, hold your keyboard's media button between 0.33 and 1.2 sec (1/2 sec is easy to remember)
; To skip backward/forward in a YouTube playlist, hold the "prev" or "next" media button for 1.2 seconds.
; ---
; Limitations:
; 1. Traditional media pause/resume will now be on-release instead of on-press.
; 2. Only the first YouTube video tab the script detects will be paused/resumed.
;    To detect a YouTube video tab, the script traverses tabs from left-right
;    starting with the active tab, and wraps around until it reaches the tab
;    it started on unless it finds a YouTube video tab before then.
; 3. If multiple main browser windows are open and none have a YouTube video tab focused,
;    the script will use the latest opened window.
; 4. When skipping to the previous video in a playlist, the playhead must be at least 2% through the video,
; or else it'll just rewind to the start of the video. For reference: ~5s for a 5min video, ~10s for 10min video, etc.


; -------------
; EZ VARIABLES:

; known to be compatible with firefox & chrome
browserExe := "firefox.exe"

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
	pauseYouTube := nextPrevYouTube := 0
	while (mediaButtonIsDown) {
		if (A_TickCount - ts1 >= 330) {
			if (A_TickCount - ts1 >= 1200 && button != "PlayPause") {
				nextPrevYouTube := 1
				break
			}
			if (A_TickCount - ts1 < 1200) {
				pauseYouTube := 1
				if (button = "PlayPause") {
					break
				}
			}
		}
		sleep,1
	}
	
	if !(pauseYouTube || nextPrevYouTube) {
		switch (button) {
			case "PlayPause": Send,{Media_Play_Pause}
			case "Next": Send,{Media_Next}
			case "Prev": Send,{Media_Prev}
		}
		return
	}
	
	SetTitleMatchMode,2
	
	if (!WinExist("ahk_exe" browserExe)) {
		return
	}
	
	prevhwnd := ""
	if (!WinActive("ahk_exe" browserExe) || WinActive("Picture-in-Picture")) { ; find main window even if PiP is focused
		WinGet,prevhwnd,id,A
		
		usableHwnd := ""
		WinGet,browserHwnd,list,% "ahk_exe" browserExe
		while (browserHwnd%A_Index%) {
			wingettitle,browserTitle,% "ahk_id" browserHwnd%A_Index%
			if (browserTitle != "Picture-in-Picture") { ; skip firefox's pop out video player
				if (InStr(browserTitle,"- YouTube")) { ; prefer window with active youtube tab if multiple browser windows exist
					usableHwnd := browserHwnd%A_Index%
					break
				}
				usableHwnd := browserHwnd%A_Index% ; use whatever qualifying window we found last
			}
		}
		
		if (usableHwnd) {
			WinActivate,% "ahk_id" usableHwnd
			WinWaitActive,% "ahk_id" usableHwnd,,3
			if (ErrorLevel) {
				return ; somefins wrong
			}
		} else {
			return ; i guess PiP was the only window? lol
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
		if (pauseYouTube) {
			switch (button) {
				case "PlayPause": Send,k
				case "Next": Send,k{l 2}k ; user may be more distracted while in another window, so larger rewind
				case "Prev": Send,k{j 2}k ; keeping it consistent ("k" before/after to avoid weird audio)
			}
		}
		if (nextPrevYouTube) {
			switch (button) {
				case "Next": Send,+n
				case "Prev":
					; if the video playhead is at > ~2%, youtube will simply rewind to the start of the vid. therefore we +p twice
					; user of this script should take note not to press this until the vid has played a little (~5s for a 5min video)
					Send,+p
					sleep,50
					Send,+p
			}
		}
	}
	
	Send,% "^{PgUp " tabCycles "}"
	if (prevhwnd) {
		WinActivate,% "ahk_id" prevhwnd
	}
	
	; avoid accidental double-presses on bad keyboard button
	keywait,Media_Play_Pause
	keywait,Media_Next
	keywait,Media_Prev
	sleep,150
	
}
