; NOTE: Meter bar characters are UTF, so to run this, either the .ahk must be saved as UTF-8 BOM and interpreted with Unicode AutoHotkey, or just replace the UTF symbol with an underscore or something.

; This script is a heavily modified version of an example from the VA docs, so comments about VA functionality are still included.

; This script is designed for 2-channel stereo only and I can't vouch for its reliability otherwise.

; This is not the best looking visualizer but it does the job :- )


#SingleInstance, Force
setbatchlines,-1
; #Include %A_ScriptDir%\Lib\VA.ahk ; https://autohotkey.com/board/topic/21984-vista-audio-control-functions/

MeterLength := 30
MeterLengthInclChan := MeterLength + 1 ; add 1 row for channel name L/R

MeterTextSize := 8
MeterTextWidth := MeterTextSize * 2
MeterWindowWidth := MeterTextWidth * 2

lxpos := 0 + 25 ; left channel x
rxpos := (A_ScreenWidth - MeterWindowWidth) - 25 ; right channel x
ypos := (A_ScreenHeight - (67*MeterTextSize)) // 2 ; something like that, lol

Gui,New,+HwndhwndLeft
; +E0x02000000 +E0x00080000 - https://www.autohotkey.com/boards/viewtopic.php?t=77668
; +E0x20 - https://autohotkey.com/board/topic/72536-solved-click-through-a-gui/
Gui,hwndLeft:-Caption AlwaysOnTop -DPIScale +LastFound +Disabled +ToolWindow +E0x02000000 +E0x00080000 +E0x20
Gui,hwndLeft:Color,000000
WinSet,TransColor,000000
Gui,hwndLeft:Font,s%MeterTextSize% cFFFFFF q3,Verdana
Gui,hwndLeft:Add,Text,w%MeterTextWidth% vLText r%MeterLengthInclChan%,
Gui,hwndLeft:Show,w%MeterWindowWidth% x%lxpos% y%ypos%

Gui,New,+HwndhwndRight
Gui,hwndRight:-Caption AlwaysOnTop -DPIScale +LastFound +Disabled +ToolWindow +E0x02000000 +E0x00080000 +E0x20
Gui,hwndRight:Color,000000
WinSet,TransColor,000000
Gui,hwndRight:Font,s%MeterTextSize% cFFFFFF q3,Verdana
Gui,hwndRight:Add,Text,w%MeterTextWidth% vRText r%MeterLengthInclChan%,
Gui,hwndRight:Show,w%MeterWindowWidth% x%rxpos% y%ypos%


; ---

audioMeter := VA_GetAudioMeter()
VA_IAudioMeterInformation_GetMeteringChannelCount(audioMeter, channelCount)

; "The peak value for each channel is recorded over one device
;  period and made available during the subsequent device period."
VA_GetDevicePeriod("capture", devicePeriod)

;settimer,UpdateGUI,15 ; ~63Hz - flickers, somehow
;settimer,UpdateGUI,17 ; ~59Hz


Loop
{
	; Get the peak values of all channels.
	VarSetCapacity(peakValues, channelCount*4)
	VA_IAudioMeterInformation_GetChannelsPeakValues(audioMeter, channelCount, &peakValues)
	
	loop % channelCount {
		if (a_index = 1)
			meterL := MakeMeter(NumGet(peakValues, A_Index*4-4, "float"), MeterLength, "L")
		if (a_index = 2)
			meterR := MakeMeter(NumGet(peakValues, A_Index*4-4, "float"), MeterLength, "R")
	}
	
	;sleep,% devicePeriod ; most accurate values - use settimer example above this loop instead of GoSub
	
	; less accurate values (only most recent period (my device's are 10ms), no time-averaging), less cpu time.
	; range: 22ms (below this flickers) - 100 (recommended max but can go above)
	gosub,UpdateGUI
	sleep,50 ; 50ms = ~20Hz
}


MakeMeter(fraction, MeterLength, channel) {
	overallindex := 0
	loop % MeterLength - Round(fraction*MeterLength) ; round to int cuz loop % always rounds down (eg loop % 0.9999*1 will never run)
		meter := ++overallindex = 1?    (A_IsUnicode? "▭" : ".")    :    meter "`n" (A_IsUnicode? "▭" : ".")
	loop % Round(fraction*MeterLength)
		meter := ++overallindex = 1?    (A_IsUnicode? "▬" : "_")    :    meter "`n" (A_IsUnicode? "▬" : "_")
	return meter "`n" channel
}


UpdateGUI:
	GuiControl,hwndLeft:Text,LText,%meterL%
	GuiControl,hwndRight:Text,RText,%meterR%
return




; end main script frontend
; --------------------













; --- RELEVANT VA.AHK FUNCTIONS MANUALLY IMPORTED FOR PORTABILITY ---
; https://autohotkey.com/board/topic/21984-vista-audio-control-functions/


; --- referenced directly in script:

VA_GetAudioMeter(device_desc="playback")
{
    if ! device := VA_GetDevice(device_desc)
        return 0
    VA_IMMDevice_Activate(device, "{C02216F6-8C67-4B5B-9D00-D008E73E0064}", 7, 0, audioMeter)
    ObjRelease(device)
    return audioMeter
}
VA_IAudioMeterInformation_GetMeteringChannelCount(this, ByRef ChannelCount) {
    return DllCall(NumGet(NumGet(this+0)+4*A_PtrSize), "ptr", this, "uint*", ChannelCount)
}
VA_GetDevicePeriod(device_desc, ByRef default_period, ByRef minimum_period="")
{
    defaultPeriod := minimumPeriod := 0
    if ! device := VA_GetDevice(device_desc)
        return false
    VA_IMMDevice_Activate(device, "{1CB9AD4C-DBFA-4c32-B178-C2F568A703B2}", 7, 0, audioClient)
    ObjRelease(device)
    ; IAudioClient::GetDevicePeriod
    DllCall(NumGet(NumGet(audioClient+0)+9*A_PtrSize), "ptr",audioClient, "int64*",default_period, "int64*",minimum_period)
    ; Convert 100-nanosecond units to milliseconds.
    default_period /= 10000
    minimum_period /= 10000    
    ObjRelease(audioClient)
    return true
}
VA_IAudioMeterInformation_GetChannelsPeakValues(this, ChannelCount, PeakValues) {
    return DllCall(NumGet(NumGet(this+0)+5*A_PtrSize), "ptr", this, "uint", ChannelCount, "ptr", PeakValues)
}



; --- referenced by those above:

VA_GetDevice(device_desc="playback")
{
    static CLSID_MMDeviceEnumerator := "{BCDE0395-E52F-467C-8E3D-C4579291692E}"
        , IID_IMMDeviceEnumerator := "{A95664D2-9614-4F35-A746-DE8DB63617E6}"
    if !(deviceEnumerator := ComObjCreate(CLSID_MMDeviceEnumerator, IID_IMMDeviceEnumerator))
        return 0
    
    device := 0
    
    if VA_IMMDeviceEnumerator_GetDevice(deviceEnumerator, device_desc, device) = 0
        goto VA_GetDevice_Return
    
    if device_desc is integer
    {
        m2 := device_desc
        if m2 >= 4096 ; Probably a device pointer, passed here indirectly via VA_GetAudioMeter or such.
        {
            ObjAddRef(device := m2)
            goto VA_GetDevice_Return
        }
    }
    else
        RegExMatch(device_desc, "(.*?)\s*(?::(\d+))?$", m)
    
    if m1 in playback,p
        m1 := "", flow := 0 ; eRender
    else if m1 in capture,c
        m1 := "", flow := 1 ; eCapture
    else if (m1 . m2) = ""  ; no name or number specified
        m1 := "", flow := 0 ; eRender (default)
    else
        flow := 2 ; eAll
    
    if (m1 . m2) = ""   ; no name or number (maybe "playback" or "capture")
    {
        VA_IMMDeviceEnumerator_GetDefaultAudioEndpoint(deviceEnumerator, flow, 0, device)
        goto VA_GetDevice_Return
    }

    VA_IMMDeviceEnumerator_EnumAudioEndpoints(deviceEnumerator, flow, 1, devices)
    
    if m1 =
    {
        VA_IMMDeviceCollection_Item(devices, m2-1, device)
        goto VA_GetDevice_Return
    }
    
    VA_IMMDeviceCollection_GetCount(devices, count)
    index := 0
    Loop % count
        if VA_IMMDeviceCollection_Item(devices, A_Index-1, device) = 0
            if InStr(VA_GetDeviceName(device), m1) && (m2 = "" || ++index = m2)
                goto VA_GetDevice_Return
            else
                ObjRelease(device), device:=0

VA_GetDevice_Return:
    ObjRelease(deviceEnumerator)
    if devices
        ObjRelease(devices)
    
    return device ; may be 0
}
VA_IMMDevice_Activate(this, iid, ClsCtx, ActivationParams, ByRef Interface) {
    return DllCall(NumGet(NumGet(this+0)+3*A_PtrSize), "ptr", this, "ptr", VA_GUID(iid), "uint", ClsCtx, "uint", ActivationParams, "ptr*", Interface)
}



; --- referenced by those above:

VA_IMMDeviceEnumerator_GetDevice(this, id, ByRef Device) {
    return DllCall(NumGet(NumGet(this+0)+5*A_PtrSize), "ptr", this, "wstr", id, "ptr*", Device)
}
VA_IMMDeviceEnumerator_GetDefaultAudioEndpoint(this, DataFlow, Role, ByRef Endpoint) {
    return DllCall(NumGet(NumGet(this+0)+4*A_PtrSize), "ptr", this, "int", DataFlow, "int", Role, "ptr*", Endpoint)
}
VA_IMMDeviceEnumerator_EnumAudioEndpoints(this, DataFlow, StateMask, ByRef Devices) {
    return DllCall(NumGet(NumGet(this+0)+3*A_PtrSize), "ptr", this, "int", DataFlow, "uint", StateMask, "ptr*", Devices)
}
VA_IMMDeviceCollection_GetCount(this, ByRef Count) {
    return DllCall(NumGet(NumGet(this+0)+3*A_PtrSize), "ptr", this, "uint*", Count)
}
VA_IMMDeviceCollection_Item(this, Index, ByRef Device) {
    return DllCall(NumGet(NumGet(this+0)+4*A_PtrSize), "ptr", this, "uint", Index, "ptr*", Device)
}
VA_GetDeviceName(device)
{
    static PKEY_Device_FriendlyName
    if !VarSetCapacity(PKEY_Device_FriendlyName)
        VarSetCapacity(PKEY_Device_FriendlyName, 20)
        ,VA_GUID(PKEY_Device_FriendlyName :="{A45C254E-DF1C-4EFD-8020-67D146A850E0}")
        ,NumPut(14, PKEY_Device_FriendlyName, 16)
    VarSetCapacity(prop, 16)
    VA_IMMDevice_OpenPropertyStore(device, 0, store)
    ; store->GetValue(.., [out] prop)
    DllCall(NumGet(NumGet(store+0)+5*A_PtrSize), "ptr", store, "ptr", &PKEY_Device_FriendlyName, "ptr", &prop)
    ObjRelease(store)
    VA_WStrOut(deviceName := NumGet(prop,8))
    return deviceName
}



; --- referenced by those above:

VA_GUID(ByRef guid_out, guid_in="%guid_out%") {
    if (guid_in == "%guid_out%")
        guid_in :=   guid_out
    if  guid_in is integer
        return guid_in
    VarSetCapacity(guid_out, 16, 0)
	DllCall("ole32\CLSIDFromString", "wstr", guid_in, "ptr", &guid_out)
	return &guid_out
}
VA_IMMDevice_OpenPropertyStore(this, Access, ByRef Properties) {
    return DllCall(NumGet(NumGet(this+0)+4*A_PtrSize), "ptr", this, "uint", Access, "ptr*", Properties)
}
VA_WStrOut(ByRef str) {
    str := StrGet(ptr := str, "UTF-16")
    DllCall("ole32\CoTaskMemFree", "ptr", ptr)  ; FREES THE STRING.
}
