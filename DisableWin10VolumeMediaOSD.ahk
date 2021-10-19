; DisableWin10VolumeMediaOSD.ahk by github:hoffr
; despite the name, this does not actually 'disable' or remove the windows 10 volume and media osd,
; but instead moves its functional and visual ui offscreen so that the user cannot interact with it,
; unlike HideWin10VolumeOSD aka 3RVX OSD-hiding code port,
; which allowed the user to accidentally click an invisible 'hidden' osd and max volume to 100
; run on sentences are cool
; this is basically abandonware, a highly simplified version of a massive project i gave up on after realizing how wacky the win10 osd is
; it may not be reliable or competent on some fronts, but i've been using it for months now with no issues.


#SingleInstance,Off
if (!A_IsAdmin)	{
	run,% "*RunAs " A_ScriptFullPath
	exitapp,0
}
#SingleInstance,Force
SetBatchLines,-1

SendEvent,{Volume_Down}
SendEvent,{Volume_Up}

loop {
	if (hwndHost:=FindOSD()) {
		WinMove,% "ahk_id" hwndHost,,-99999,-99999
		WinMinimize,% "ahk_id" hwndHost
	}
	sleep,15
}

FindOSD() {
	paircount:=hParent:=0
	 ; finds this class unlike WinExist() for some reason
	while (hParent := DllCall("FindWindowEx","Ptr",0,"Ptr",hParent,"Str","NativeHWNDHost","Str","")) { ; get next NativeHWNDHost sibling if any
		; verify if this is likely to be the correct window
		if (DllCall("FindWindowEx","Ptr",hParent,"Ptr",0,"Str","DirectUIHWND","Str","")) {
			if (++paircount > 1)
				return "" ; if there are multiple NativeHWNDHost+DirectUIHWND pairs, finding our target is impossible
			else
				hwndHost:=hParent
		}
	}
	return hwndHost
}


