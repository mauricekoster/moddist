#include-once

; Settings dir

Func SettingsFolder()

	$homedir = @MyDocumentsDir

	$d = $homedir & "\.settings"
	If FileExists( $d ) Then
		Return $d
	EndIf

	$d = $homedir & "\_settings"
	If FileExists( $d ) Then
		Return $d
	EndIf

	$d = $homedir & "\settings"
	If FileExists( $d ) Then
		Return $d
	EndIf

	Return @ScriptDir

EndFunc

Func CreateSettingsFolder()
	$homedir = @MyDocumentsDir

	$d = $homedir & "\.settings"
	If not FileExists( $d ) Then
		DirCreate( $d )
	EndIf
EndFunc

;CreateSettingsFolder()
ConsoleWrite( "Settings dir: " & SettingsFolder() & @CRLF )
