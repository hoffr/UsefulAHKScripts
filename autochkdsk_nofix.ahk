#SingleInstance,Off
if (!A_IsAdmin)
{
	run,% "*RunAs " A_ScriptFullPath
	exitapp
}
#SingleInstance,Force

setbatchlines,-1
asleepDurationMS := 100,    awakeDurationMS := 15 ; 100:50 = 33.33% uptime: (awakeDurationMS * 100) / (asleepDurationMs + awakeDurationMS) = x% uptime
verboseTray := 0
gosub,CheckAllDrives
exitapp


CheckAllDrives:
	if (verboseTray)
		traytip,% "AutoCHKDSK",% "Checking all drives..."
	
	DriveGet,drivelist,List
	driveArr := strsplit(drivelist)
	loop % driveArr.count()
	{
		letter := driveArr[A_Index]
		time := A_YYYY "-" A_MM "-" A_DD "_" A_Hour "-" A_Min "-" A_Sec "-" A_MSec
		outputPath := TEMP "\chkdsk_ahk_output_drive_" letter "_" time ".txt"
		
		; --- begin collect running chkdsk process list and compare with list gotten after run command
		
		processArr1:=[]
		for process in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process where Name='chkdsk.exe'")
			processArr1.Push(process.ProcessID)
		
		run,% "cmd.exe /c chkdsk " letter ": > " outputPath,,Hide,cmdPID
		
		loop ; wait for new chkdsk, make sure its not an old one
		{
			sleep,250
			Process,Exist,chkdsk.exe
			if (processArr1[1])
			{
				loop % processArr1.Count()
				{
					if !(errorlevel = processArr1[A_Index])
						break,2
				}
			} else {
				if errorlevel
					break
			}
			
			if (A_Index = 4) ; 1 sec
			{
				FileRead,fileContents,% outputPath
				if !(InStr(fileContents,"Running CHKDSK in read-only mode."))
				{
					if (verboseTray)
						traytip,% "AutoCHKDSK",% "CHKDSK skipped drive " letter "`nCHKDSK output: " outputPath,,1
					continue,2 ; skip to next drive letter
				}
			}
		}
		chkdskPID := errorlevel
		
		; --- end dumb chkdsk list crap
		
		
		while !(hwnd := DllCall("OpenProcess","UInt", 0x1F0FFF,"Int",0,"Int",chkdskPID))
			sleep,100
		settimer,SuspendResume,% awakeDurationMS
		
		loop {
			sleep,1000
			Process,Exist,% cmdPID
		} until !(errorlevel)
		
		settimer,SuspendResume,Off

		FileRead,fileContents,% outputPath
		if !(errorlevel)
		{
			if !(InStr(fileContents,"No further action is required."))
				GUIMsgBox("A chkdsk /f or /r is needed for drive " letter)
				;traytip,% "AutoCHKDSK",% "A chkdsk /f or /r is needed for drive " letter,,1
		}
		else
			GUIMsgBox("Error reading chkdsk output to file: " outputPath "`nA_LastError: " A_LastError)
			;traytip,% "AutoCHKDSK",% "Error reading chkdsk output to file: " outputPath "`nA_LastError: " A_LastError,,3
	}
return


SuspendResume:
	DllCall("ntdll.dll\NtSuspendProcess","Int",hwnd)
	sleep,% asleepDurationMS
	DllCall("ntdll.dll\NtResumeProcess","Int",hwnd)
return


GUIMsgBox(msg) ; mimic msgbox but start minimized and never steal focus until user activates it
{
	; until it's improved, this should only be used right before the script closes
	Gui,+HwndMyHwnd
	Gui,Margin,0,0
	Gui,Add,ActiveX,vWB w310 h75, Shell.Explorer
	Gui,Font,s9 Norm,Segoe UI
	Gui,Add,Text,x10 y15 BackgroundTrans,% msg
	Gui,Add,Button,y88 x220 w80 h27 default,OK
	Gui,Show,h125 Minimize

	; remove title bar icon:
	WinWaitActive,% "ahk_id" MyHwnd
	Gui,Hide
	Gui,+ToolWindow
	Gui,+0x94C80000
	Gui,-ToolWindow
	Gui,Show
	pause,on
}

ButtonOK:
GuiClose:
pause,off
return
