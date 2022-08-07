; grandma virus saver 9000 - make sure to only keep one web browser installed and usable, and have its download location be \Downloads

#SingleInstance,Force
SetBatchLines,-1

ext:=["AHK","7Z","ZIP","RAR","PY","JAR","INF1","VBSCRIPT","GADGET","BAT","BIN","CMD","COM","CPL","EXE","INS","INX","ISU","JOB","JSE","LNK","MSC","MSI","MSP","MST","PAF","PIF","PS1","REG","RGS","SCR","SCT","SHB","SHS","U3P","VB","VBE","VBS","WS","WSF","WSH"]

loop {
	loop % ext.Count()
	{
		mainindex := A_Index
		Loop,Files,% "C:\Users\" . A_UserName . "\Downloads\*." ext[mainindex],F
		{
			if (A_LoopFileLongPath)
				FileRecycle,% A_LoopFileLongPath
		}
	}
	sleep,100
}