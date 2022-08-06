; TF2 Resolution Setter by github:hoffr / reddit:Splongus
; Purpose: Automatically set nonstandard resolutions for TF2 on game launch. Optionally supports AMD Integer Scaling for them crispy pixels.
; Details:
; TF2's engine doesn't allow you to set resolutions they've not already pre-defined through the Options menu or even with mat_setvideomode.
; This bypasses that restriction by briefly restricting the max supported resolution the game sees to your preferred nonstandard res.
; This forces Source to create a video mode preset for that resolution.
; Once that's done we can set the desktop res back to normal and use the nonstandard res in-game, so when tabbing out, the desktop won't be low-res.


; ---

; TWEAKABLE VARIABLES AND IMPORTANT INFO:

; Script works best when TF2 launches in fullscreen (whether with fullscreen optimizations enabled or not).
; Fullscreen launch ensures desktop window/icon positioning/size don't get messed up by resolution changes,
; and sort of ensures you can't tab out of the game while it's loading and setting up resolutions (if you do, res switching will 'cancel').
;
; You can use windowed mode once the game loads in by setting this variable to 1:
; "-noborder" must be a launch option if you want that. It's compatible with "-fullscreen", which will override noborder until the game is windowed.
windowed := 0


; optional: actual native monitor res, or 'native' you'd like to use for the desktop, eg. h_native := 1080
w_native := A_ScreenWidth
h_native := A_ScreenHeight


; Use AMD integer scaling? If > 0, game res is set to x/y, x being the value set here and y being [w/h]_native.
; Only way to enable proper AMD integer scaling is to use a number for x that results in an whole number for each width and height.
; EDIT - I DISAGREE: I'd recommend you only enable integer scaling in TF2 if your monitor's resolution is w >= 2560 AND h >= 1920.
;
; Refresh rate doesn't matter, it'll use your native res refresh.
; For effective resolutions smaller than either w=640 or h=480, launch option "-small" is required,
; and some text will be unreadable or effectively invisible (eg. chat box not displaying text at all).
;
; If you insist on int scaling using "-small", then I've made a ToonHUD preset that SHOULD render everything readably down to 640x360, but it's not pretty:
; v1: https://toonhud.com/user/snowdroll/theme/6JTWXUKV/
useAMDIntegerScaling := 2


; if useAMDIntegerScaling = False, we'll use these values for game resolution instead:
w_preferredGame := 1280
h_preferredGame := 720


; native profile refresh rate
refresh := 144


; QRes.exe path (must have quotes):
qresPath := "C:\PortableApps\QRes\QRes.exe"


; on dev's system, explorer likes to crash sometimes (likely cause is StartIsBack++).
; this option will suspend all explorer.exe processes while res is changing:
explorerCrashFix := True




; --- a lil setup:

#Singleinstance,Force
#InstallKeybdHook
#KeyHistory 0

w_smaller := useAMDIntegerScaling?  w_native//useAMDIntegerScaling  :  w_preferredGame
h_smaller := useAMDIntegerScaling?  h_native//useAMDIntegerScaling  :  h_preferredGame


; --- main loop:

loop
{
	Process,Exist,hl2.exe
	if (ErrorLevel)
	{
		if (A_Index != 1)
			GameIsRunning(False) ; if game launched after script launched, set up res and all that
		if (A_Index = 1)
			GameIsRunning(True) ; if game was running on script launch, don't set up res until game has closed and re-opened
	}
	sleep,1000
}


; --- funcs n subs:

GameIsRunning(wasRunningOnScriptLaunch)
{
	global
	
	for process in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process where ProcessID='" ErrorLevel "'")
		exePath:=process.ExecutablePath
	
	
	if (!wasRunningOnScriptLaunch)
	{
		Hotkey,$!Tab,CancelAndResetRes,On ; cancelling only affects native res
	
		gosub,GetAllWindowSizeAndPos
	
		while (!hwnd:=WinActive("ahk_exe hl2.exe")) ; wait till game is in focus
		{
			Process,Exist,hl2.exe
			if (ErrorLevel)
				sleep,250
			else
				return ; process must've terminated before window was created
		}
		sleep,500
		
		if (explorerCrashFix)
			SuspendResumeProccessesThatMatchCriteria("explorer.exe"),    suspended:=True
		
		; force game to add small res to its usable res list by temporarily restricting desktop res
		;run,% qresPath " /x:" w_smaller " /y:" h_smaller,,Hide
		ChangeDisplayMode(w_smaller,h_smaller,refresh)
		sleep,4000 ; longer delay btwn res changes = less chance of explorer crashing (*startisback++???)
		
		; set desktop to native res
		;run,% qresPath " /x:" w_native " /y:" h_native " /r:" refresh,,Hide
		ChangeDisplayMode(w_native,h_native,refresh)
		
		sleep,4000
		
		if (!WinExist("ahk_id" hwnd))
			gosub,CancelAndResetRes
		
		; queue a cvar for when the main menu loads in - run game in the small res
		run,% exePath " -hijack ""+mat_setvideomode " w_smaller " " h_smaller " " windowed """",,Hide
		
		; preferably this would happen after we're sure game res finished changing, but idk a way to do that
		if (explorerCrashFix)
			SuspendResumeProccessesThatMatchCriteria("explorer.exe"),    suspended:=False
		
		Hotkey,$!Tab,,Off
	
	} else {
		traytip,% "TF2 Res Setter",% "Game must be restarted for resolution change to take effect",,0x1
		settimer,SilenceTray,-5000
	}
	
	; wait for process termination, restore window positions and sizes on first game de-focus
	loop {
		sleep,1000
		Process,Exist,hl2.exe
		if (!wasRunningOnScriptLaunch) {
			if (!winrestored && !WinActive("ahk_id" hwnd)) {
				gosub,RestoreAllWindowSizeAndPos
				winrestored := 1
			}
		}
	} until (!ErrorLevel)
	
	reload ; easier this way
	exitapp
}


CancelAndResetRes:
	if (explorerCrashFix && !suspended)
		SuspendResumeProccessesThatMatchCriteria("explorer.exe"),    suspended := True
	
	;run,% qresPath " /x:" w_native " /y:" h_native " /r:" refresh,,Hide
	ChangeDisplayMode(w_native,h_native,refresh) ; no effect is already native
	sleep,1500 ; allow desktop res to hopefully be native before we tab into it (prevents window sizes from messing up)
	
	if (explorerCrashFix && suspended)
		SuspendResumeProccessesThatMatchCriteria("explorer.exe"),    suspended := False
	
	sendevent,!{Tab}
	if (WinExist("ahk_id" hwnd))
		run,% exePath " -hijack ""+mat_setvideomode " w_native " " h_native " " windowed """",,Hide ; native is a safe fallback
reload
exitapp


SilenceTray:
	TrayTip
return


GetAllWindowSizeAndPos:
	dhw:=A_DetectHiddenWindows
	DetectHiddenWindows,Off
	WinGet,winList,List
	winArr := []
	loop
	{
		if (!winList%A_Index%)
			break
		WinGetTitle,title,% "ahk_id" winList%A_Index%
		if (title != "" || title != "Start")
			winArr.Push(winList%A_Index%)
	}
	loop % winArr.Count()
	{
		WinGetPos,x1,y1,w1,h1,% "ahk_id" winArr[A_Index]
		WinGet,m1,MinMax,% "ahk_id" winArr[A_Index]
		winArr[A_Index] .= "," x1 "," y1 "," w1 "," h1 "," m1
	}
	DetectHiddenWindows,% dhw
return


RestoreAllWindowSizeAndPos:
	dhw:=A_DetectHiddenWindows
	DetectHiddenWindows,Off
	loop % winArr.Count()
	{
		index_L1 := A_Index
		loop,parse,% winArr[index_L1],`,
		{
			switch A_Index
			{
				case 1: hwnd := a_loopfield
				case 2: x1 := a_loopfield
				case 3: y1 := a_loopfield
				case 4: w1 := a_loopfield
				case 5: h1 := a_loopfield
				case 6: m1 := a_loopfield
			}
		}
		
		WinGetPos,x2,y2,w2,h2,% "ahk_id" hwnd
		WinGet,m2,MinMax,% "ahk_id" hwnd
		
		if ((hwnd "," x1 "," y1 "," w1 "," h1 "," m1) != (hwnd "," x2 "," y2 "," w2 "," h2 "," m2))
		{
			WinMove,% "ahk_id" hwnd,,% x1,% y1,% w1,% h1
			if (m1 != m2)
				WinRestore,% "ahk_id" hwnd
		}
	}
	DetectHiddenWindows,% dhw
return


SuspendResumeProccessesThatMatchCriteria(processName:="errorname.exe")
{
	; toggle suspend/resume for all processes that match processName
	static processArr ; will be 3D array
	
	if (!processArr)
		processArr := []
	
	if (!processArr[processName])
	{
		processArr[processName] := [],    processArr[processName]["PIDArr"] := [],    processArr[processName]["HWNDArr"] := []
		
		for process in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process where Name='" processName "'")
			processArr[processName]["PIDArr"].Push(process.ProcessID)

		; suspend all
		loop % processArr[processName]["PIDArr"].Count()
		{
			processArr[processName]["HWNDArr"].Push( DllCall("OpenProcess","UInt",0x1F0FFF,"Int",0,"Int",processArr[processName]["PIDArr"][A_Index]) )
			DllCall("ntdll.dll\NtSuspendProcess","Int",processArr[processName]["HWNDArr"][A_Index])
		}
	} else {
		
		; resume all
		loop % processArr[processName]["HWNDArr"].Count()
		{
			DllCall("ntdll.dll\NtResumeProcess","Int",processArr[processName]["HWNDArr"][A_Index])
			DllCall("CloseHandle","Int",processArr[processName]["HWNDArr"][A_Index])
		}
		processArr[processName] := ""
	}
}


ChangeDisplayMode(width,height,refresh)
{
	VarSetCapacity(deviceMode,156,0)
	NumPut(156,deviceMode,			36)
	DllCall("EnumDisplaySettingsA","UInt",0,"Int",-1,"Ptr",&deviceMode)
	NumPut(0x5c0000,deviceMode,		40)
	NumPut(32,deviceMode,			104) ; 32-bit color depth
	NumPut(width,deviceMode,		108)
	NumPut(height,deviceMode,		112)
	NumPut(refresh,deviceMode,		120)
	Return DllCall("ChangeDisplaySettingsA","Ptr",&deviceMode,"UInt",0)
}

/*
; FOR TESTING
^+l::
	run,% qresPath " /x:" w_native " /y:" h_native " /r:" refresh,,Hide
exitapp
*/
