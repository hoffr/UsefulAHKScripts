#SingleInstance,Off
if (!A_IsAdmin)
{
	run,% "*RunAs " A_ScriptFullPath
	exitapp
}
runwait,% "C:\PortableApps\PsTools\PsExec.exe -i -d -s SCHTASKS /Change /TN """"Microsoft\Windows\UpdateOrchestrator\Reboot_AC"""" /DISABLE"
runwait,% "C:\PortableApps\PsTools\PsExec.exe -i -d -s SCHTASKS /Change /TN """"Microsoft\Windows\UpdateOrchestrator\Reboot_Battery"""" /DISABLE"

; these will lock you and every other account out of editing this, careful
runwait, % "icacls """"%WINDIR%\System32\Tasks\Microsoft\Windows\UpdateOrchestrator\Reboot_AC"""" /inheritance:r /deny """"Everyone:F"""" /deny """"SYSTEM:F"""" /deny """"Local Service:F"""" /deny """"Administrators:F"""""
runwait, % "icacls """"%WINDIR%\System32\Tasks\Microsoft\Windows\UpdateOrchestrator\Reboot_Battery"""" /inheritance:r /deny """"Everyone:F"""" /deny """"SYSTEM:F"""" /deny """"Local Service:F"""" /deny """"Administrators:F"""""

; https://superuser.com/questions/1268789/disable-updateorchestrator-reboot-task