; youtube_letterbox_pause_reenabler.ahk by github:hoffr / reddit:Splongus
; -------------------------------------
; Sometimes it's the little things in life... that piss me off!
; YouTube recently removed the ability to pause a video by clicking the black letterboxed space around it.
; I don't know javascript, so here's this atrocity of a workaround.
; ---
; Limitations:
; THIS MUST BE RUN AS ADMIN if you want your left click to work at all while an admin window is active. For real.
; It only works if the browser is maximized and the page is scrolled all the way up.
; If it's not the active window but it's still visible, then if you click on the letterbox space
; it should work unless the scrollbar is blocked by another window.
; -------------------------------------


; ALL OF THESE VALUES MUST BE CHANGED FOR SCRIPT TO WORK; USE WINDOW SPY TO GET PROPER VALUES:

browserExe := "firefox.exe" ; should work fine with chrome

; Define the bounding rectangle of your YouTube video when the page is scrolled all the way up.
; REMINDER: These must be fullscreen coords. Script won't work if browser is windowed.
; Don't include youtube's video player control bar on the bottom!

; hoffr's default values: 2560x1440 monitor, 138% DPI scaling, 120% page zoom on youtube in firefox.
y_min := 246    ; highest (as in visibly higher, not the number itself) y coordinate to consider clicks within
y_max := 1109    ; lowest y coord
x_min := 0    ; farthest left x coord
x_max := 2532    ; farthest right x coord (watch out for that scrollbar!)


; coordinates of your scrollbar, right below the [^] (scroll-up) arrow. purpose: page must be scrolled up for script to work lol.
; if you are scrolled all the way to the top of the page, this coordinate must see the color of the scrollbar itself (darker color).
; if scrolled down at all, it must see the color of the scrollbar's background (lighter color).
x_sb := 2546
y_sb := 178

; scrollbar color (Win7/vista/xp might have gradients, in which case UR SCREWED)
sb_bar_color_hover := "0xA6A6A6" ; mouse hovering over scrollbar ("0x" MUST precede the color code)
sb_bar_color_nohover := "0xCDCDCD"	; if your "hover" color is "0xA6A6A6" then don't mess with this "nohover" one
									; otherwise you'll have to screenshot it & put it in a paint program and get its color that way

; ---

SetTitleMatchMode,2
CoordMode,Mouse,Screen
CoordMode,Pixel,Screen

#If (WinExist("ahk_exe" browserExe))
	LButton::
		MouseGetPos,x_mouse,y_mouse,hwnd
		PixelGetColor,colormouse,x_mouse,y_mouse,RGB	; mouse, in case there are player controls over actual video
		PixelGetColor,colorsb,x_sb,y_sb,RGB				; scrollbar
		
		if (WinExist(" - YouTube")
		&& (WinExist("ahk_class MozillaWindowClass ahk_id " hwnd)	; if mouse is over browser window (firefox edition)
		|| WinExist("ahk_class Chrome_WidgetWin_1 ahk_id " hwnd))	; chrome edition
		&& colorsb = sb_bar_color_nohover							; if we're sure scrollbar is at very top
		&& x_mouse <= x_max && x_mouse >= x_min						; if mouse is within our defined bounding rectangle
		&& y_mouse <= y_max && y_mouse >= y_min
		&& colormouse = "0x000000") {								; if mouse is likely over letterboxing
			if (WinActive(" - YouTube")) { ; if we are able to send successful key press
				KeyWait,LButton ; keeping it faithful
				send,k
			} else { ; click into the yt window first, then send k
				send,{LButton Down}
				KeyWait,LButton
				send,{LButton Up}
				send,k
			}
		} else { ; simulate natural click
			send,{LButton Down}
			KeyWait,LButton
			send,{LButton Up}
		}
	return
#If
