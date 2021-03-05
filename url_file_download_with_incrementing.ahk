; url_file_download_with_incrementing.ahk by github:hoffr / reddit:Splongus
; Downloads a file from URL and if necessary increments its count, eg. "My File (1).txt" etc.
; ---
; LIMITATIONS: Will not work for URLs that do not include a file extension.


; EZ VARIABLES:

renameFile := True
renameTo_NoExt := "the file's new name"
fileURL := "https://www.autohotkey.com/download/ahk-install.exe"
destinationFolder := USERPROFILE . "\Downloads\" ; NOTE: must have final backslash. full paths are allowed

; ---

; CTRL+SHIFT+L - Download the file, renaming if specified, and increment its file name counter if necessary
^+L::
	
	fileURLArr := StrSplit(fileURL,"/") ; split by delimiter "/"
	fileNameFull := fileURLArr[fileURLArr.Count()] ; get only last element
	
	fileExtArr := StrSplit(fileNameFull,".")
	fileExtOnly := fileExtArr[fileExtArr.Count()]
	
	fileNameArr := StrSplit(fileNameFull,".")

	loop % (fileNameArr.Count() - 1) { ; if file name has periods in it, this will concatonate them together
		if (A_Index != fileNameArr.Count() - 1) {
			fileNameOnly .= fileNameArr[A_Index] . "."
		} else {
			fileNameOnly .= fileNameArr[A_Index]
		}
	}
	
	; if file exists already, count up until it doesn't, and then download/rename with that counter.
	; if it exists, save it without the counter (counter/parentheses are set blank)
	counter := paren1 := paren2 := ""
	loop {
		
		if (renameFile) {
			fileNameFinal := renameTo_NoExt . paren1 . counter . paren2 . "." . fileExtOnly
		} else {
			fileNameFinal := fileNameOnly . paren1 . counter . paren2 . "." . fileExtOnly
		}
		
		++counter
		paren1 := " ("
		paren2 := ")"
		
	} until (!FileExist(destinationFolder fileNameFinal)   ||   ai:=A_Index = 999)
	
	if (ai) {
		msgbox,% "error: file count too large, something's wrong"
		exitapp
	}
	
	UrlDownloadToFile,% fileURL,% destinationFolder fileNameFinal
	
return
