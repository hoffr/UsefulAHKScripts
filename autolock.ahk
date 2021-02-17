; autolock.ahk by github:hoffersrc / reddit:Splongus
; Purpose: Lock workstation after %minutestoidle% (default 5 minutes) and mute audio
; Gives 10 second warning before lock, cancellable by using mouse or keyboard


; -------------
; EZ VARIABLES:

minutestoidle := 5 ; minutes of no user input to warn user of impending lock
alerttimer := 10 ; seconds to wait after alerting user of impending lock
shouldmute := 1 ; should we mute/unmute audio on lock/unlock?


; -------------

timetoidle := 1000 * 60 * minutestoidle
cancellock := waslocked := 0
loopts := A_TickCount

loop {
	

	if (WinExist("A")) { ; if not locked
		
		if (waslocked) {
			waslocked := 0
			if (shouldmute && prelockmutestate = "Off") {
				SoundSet,+1,,MUTE
			}
			sleep,100
			TrayTip,% "AUTOLOCK",% "welcome back lol"
			sleep,1900
			TrayTip
			Continue
		}
		
		if ((timeidletrigger := A_TimeIdle) > timetoidle
		&& A_TickCount - loopts < 5000) { ; flimsy s3/s4 sleep detection
		
			soundplay,*64
			TrayTip,% "AUTOLOCK",% "Locking in " alerttimer " seconds, send input to cancel..."
			loop % alerttimer {
				if (A_TimeIdle < timeidletrigger) {
					cancellock := 1
					break
				}
				sleep,1000
			}
			
			if (cancellock) {
				TrayTip,% "AUTOLOCK",% "Lock cancelled"
				sleep,1500
				TrayTip
			} else {
				waslocked := 1
				SoundGet,prelockmutestate,,MUTE
				if (shouldmute && prelockmutestate = "Off") {
					SoundSet,1,,MUTE
				}
				DllCall("LockWorkStation")
			}
			
			cancellock := 0
		}
		
	}
	
	loopts := A_TickCount
	sleep,1000
}