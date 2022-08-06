#Persistent
setbatchlines,-1
;#NoTrayIcon

guidMinStr := "a1841308-3541-4fab-bc81-f71556f20b4a"
guidBalStr := "381b4222-f694-41f0-9685-ff5bb260df2e"

; Listen to the Windows power event "WM_POWERBROADCAST" (ID: 0x218):
OnMessage(0x218, "func_WM_POWERBROADCAST")
return


GetCurrentGUID(gCurStr) { ; get current power plan guid and convert to string
	; https://docs.microsoft.com/en-us/windows/win32/api/powersetting/nf-powersetting-powergetactivescheme
	; https://docs.microsoft.com/en-us/windows/win32/api/guiddef/ns-guiddef-guid
	DllCall("PowrProf\PowerGetActiveScheme", "Ptr", 0, "Ptr*", gCurBin)
	DllCall("ole32\StringFromCLSID", "Ptr", gCurBin, "Ptr*", lplpsz)
	gCurStr := StrGet(lplpsz, "UTF-16")
	DllCall("ole32\CoTaskMemFree", "Ptr", lplpsz)
	return gCurStr
}
;msgbox,% Trim(GetCurrentGUID(gCurStr), "{}")



; -----------------------
; modified from:
; https://autohotkey.com/board/topic/19984-running-commands-on-standby-hibernation-and-resume-events/#entry131210


/*
	This function is executed if the system sends a power event.
	Parameters wParam and lParam define the type of event:
	
	lParam: always 0
	wParam:
		PBT_APMQUERYSUSPEND             0x0000
		PBT_APMQUERYSTANDBY             0x0001
		
		PBT_APMQUERYSUSPENDFAILED       0x0002
		PBT_APMQUERYSTANDBYFAILED       0x0003
		
		PBT_APMSUSPEND                  0x0004
		PBT_APMSTANDBY                  0x0005
		
		PBT_APMRESUMECRITICAL           0x0006
		PBT_APMRESUMESUSPEND            0x0007
		PBT_APMRESUMESTANDBY            0x0008
		
		PBTF_APMRESUMEFROMFAILURE       0x00000001
		
		PBT_APMBATTERYLOW               0x0009
		PBT_APMPOWERSTATUSCHANGE        0x000A
		
		PBT_APMOEMEVENT                 0x000B
		PBT_APMRESUMEAUTOMATIC          0x0012
		
		Source: http://weblogs.asp.net/ralfw/archive/2003/09/09/26908.aspx
*/
func_WM_POWERBROADCAST(wParam, lParam)
{
	global
	
	if (lParam = 0)
	{
		
		; PBT_APMSUSPEND or PBT_APMSTANDBY
		if (wParam = 4 || wParam = 5) {
			gPrevStr := Trim(GetCurrentGUID(gCurStr),"{}")
			run,% "powercfg /setactive " guidMinStr,,Hide
			return
		}
		
		; PBT_APMRESUMESUSPEND or PBT_APMRESUMESTANDBY
		if (wParam = 7 || wParam = 8) {
			sleep,2500
			if (gPrevStr != "" && guidBalStr != gPrevStr)  ; just some more easing
			{
				run,% "powercfg /setactive " guidBalStr,,Hide
				sleep,1500
			}
			run,% "powercfg /setactive " gPrevStr,,Hide
			return
		}
		
	}
	
}
