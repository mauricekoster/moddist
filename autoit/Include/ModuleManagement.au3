#include <Array.au3>
#include <File.au3>
#include "Logging.au3"

$msgbox_title = "mpm"

Func GetModuleList($module_url)
Local $aRecords
Local $L
Dim $aList[1]

	$module_url = $module_url & "/module_list.txt"

	$temp_dir = @TempDir
	$file_module_list = $temp_dir & "\module_list.txt"
	if FileExists($file_module_list) Then
		FileDelete($file_module_list)
	EndIf

	LogInfo("Module url: " & $module_url)
	LogInfo("Module file: " & $file_module_list)

	$iRet = InetGet( $module_url, $file_module_list, 1 )
	if $iRet = 0 Then
		LogWarning( "Probleem met internet connectie. (Geen module_list.txt gevonden)" )
		MsgBox( 0, $msgbox_title, "Probleem met internet connectie. (Geen module_list.txt gevonden)")
		Return False

	EndIf
	InetClose( $iRet )

	if not FileExists($file_module_list) Then
		LogError("modulelist niet gevonden!")
	EndIf

	$regel = FileReadline( $file_module_list, 1 )
	;OutputDebug( $regel )
	If $regel <> "# MODULELIST" Then

		msgbox( 0, $msgbox_title, "Bestand is geen module lijst" )
		Return False

	EndIf


	If Not _FileReadToArray( $file_module_list, $aRecords) Then
		LogError( "Error reading log to Array  error:" & @error )
		Return False
	EndIf

	redim $aList[$aRecords[0]-1]
	for $i = 3 to $aRecords[0]
		LogDebug( $aRecords[$i] )

		$aList[$i-2] = $aRecords[$i]



	Next
	$aList[0] = $aRecords[0] - 2

	Return $aList

EndFunc


Func GetModuleInfo( $aList, $aModuleName, ByRef $Description, ByRef $URL)

	For $i = 1 to $aList[0]
		$arr = StringSplit($aList[$i], "|", 1)
		if $arr[1] == $aModuleName Then
			$Description = $arr[2]
			$URL = $arr[3]
			Return True
		EndIf
	Next

	Return False
EndFunc