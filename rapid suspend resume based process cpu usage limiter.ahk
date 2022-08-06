#NoEnv

throttleDurationS := 160 * 1000
asleepDurationMS := 200
awakeDurationMS := 1
exeName := "linpack64.exe"

; todo: make process detection more stringent
Process,Exist,% exeName
while (!ErrorLevel) {
	sleep,250
	Process,Exist,% exeName
}

setbatchlines,-1
hwnd := DllCall("OpenProcess", "uInt", 0x1F0FFF, "Int", 0, "Int", ErrorLevel)

ts1 := A_TickCount
loop {
	DllCall("ntdll.dll\NtSuspendProcess", "Int", hwnd)
	sleep,% asleepDurationMS
	DllCall("ntdll.dll\NtResumeProcess", "Int", hwnd)
	sleep,% awakeDurationMS
	;loopcount := A_Index
} ;until (A_TickCount - ts1 >= throttleDurationS)

;msgbox,% loopcount " total loops."
DllCall("CloseHandle", "Int", hwnd)

Process,Exist,% exeName
while (ErrorLevel != 0) {
	sleep,1000
	Process,Exist,% exeName
}
reload
exitapp



/*
; 100asleep:100awake = 50% uptime
; 100:0 = 0%
; 100:50 = 33.33%
; 200:15.6 = 7.8%

x       %
--- = ---
x+y   100

x=awake ms
y=asleep ms

z * (100+x) = y
y/100 = x

z = percentage you want to use
x = awake value

unsolvable, prob would have to 'scan' for x values that result close to z
or just use preset values
if scanning, can use decuctive reasoning eg. if z=32 we know x<50, if z=34 we know x>50, etc


*/