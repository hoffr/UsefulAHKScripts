; NOTE: Meter bar characters are UTF, so to run this, either the .ahk must be saved as UTF-8 BOM and interpreted with Unicode AutoHotkey, or just replace the UTF symbol with an underscore or something.

; This script is a heavily modified version of an example from the VA docs, so comments about VA functionality are still included.

; This script is designed for 2-channel stereo only and I can't vouch for its reliability otherwise.

; This is not the best looking visualizer but it does the job :- )


#SingleInstance, Force
setbatchlines,-1
#Include %A_ScriptDir%\Lib\VA.ahk ; https://autohotkey.com/board/topic/21984-vista-audio-control-functions/

MeterLength := 30

MeterTextSize := 6
MeterTextWidth := MeterTextSize * 2
MeterWindowWidth := MeterTextWidth * 2

lxpos := 0 + 25 ; left channel x
rxpos := (A_ScreenWidth - MeterWindowWidth) - 25 ; right channel x
ypos := (A_ScreenHeight - (67*MeterTextSize)) // 2 ; something like that, lol

Gui,New,+HwndhwndLeft
; +E0x02000000 +E0x00080000 - https://www.autohotkey.com/boards/viewtopic.php?t=77668
; +E0x20 - https://autohotkey.com/board/topic/72536-solved-click-through-a-gui/
Gui,hwndLeft:-Caption AlwaysOnTop -DPIScale +LastFound +Disabled +E0x02000000 +E0x00080000 +E0x20
Gui,hwndLeft:Color,000000
WinSet,TransColor,000000
Gui,hwndLeft:Font,s%MeterTextSize% bold cFFFFFF,Verdana
Gui,hwndLeft:Add,Text,w%MeterTextWidth% vLText r%MeterLength%,
Gui,hwndLeft:Show,w%MeterWindowWidth% x%lxpos% y%ypos%

Gui,New,+HwndhwndRight
Gui,hwndRight:-Caption AlwaysOnTop -DPIScale +LastFound +Disabled +E0x02000000 +E0x00080000 +E0x20
Gui,hwndRight:Color,000000
WinSet,TransColor,000000
Gui,hwndRight:Font,s%MeterTextSize% bold cFFFFFF,Verdana
Gui,hwndRight:Add,Text,w%MeterTextWidth% vRText r%MeterLength%,
Gui,hwndRight:Show,w%MeterWindowWidth% x%rxpos% y%ypos%

; ---

audioMeter := VA_GetAudioMeter()

VA_IAudioMeterInformation_GetMeteringChannelCount(audioMeter, channelCount)

; "The peak value for each channel is recorded over one device
;  period and made available during the subsequent device period."
VA_GetDevicePeriod("capture", devicePeriod)

;settimer,UpdateGUI,15 ; ~63Hz
settimer,UpdateGUI,20 ; ~50Hz
;settimer,UpdateGUI,30 ; ~31Hz
;settimer,UpdateGUI,40 ; ~25Hz
;settimer,UpdateGUI,60 ; ~15Hz

Loop
{
    ; Get the peak values of all channels.
    VarSetCapacity(peakValues, channelCount*4)
    VA_IAudioMeterInformation_GetChannelsPeakValues(audioMeter, channelCount, &peakValues)
	
    Loop %channelCount%
	{
		if a_index = 1
			meterL := MakeMeter(NumGet(peakValues, A_Index*4-4, "float"), MeterLength)
		if a_index = 2
			meterR := MakeMeter(NumGet(peakValues, A_Index*4-4, "float"), MeterLength)
	}
	
	;gosub,UpdateGUI
    Sleep, %devicePeriod%
}

MakeMeter(fraction, size)
{
    global MeterLength
	loop % MeterLength - (fraction*size)
		meter .= "`n" (A_IsUnicode? "-" : ".")
    Loop % fraction*size
			meter .= "`n" (A_IsUnicode? "▬" : "_")
    return meter
}

UpdateGUI:
	GuiControl,hwndLeft:Text,LText,%meterL%
	GuiControl,hwndRight:Text,RText,%meterR%
return
