#include-once

Local $prvMsg
Local $prvLogLevel = 0
Local $prvLogMode = 0

Dim $do_console = False		; mode = 4
Dim $do_debugview = False		; mode = 8
Dim $do_file = False			; mode = 2

Func _IIf($condition, $truepart, $falsepart)
	If $condition Then
		Return $truepart
	Else
		Return $falsepart
	EndIf
EndFunc

#Region Output

Func OutputDebug($msg)
    		
    ;Output to application attaching a console to the script engine
    ConsoleWrite($msg & @CRLF)
    ;Output to debugger (dbgview.exe)
	OutputDebugString($msg)
	
EndFunc

Func OutputDebugString($msg)
	DllCall("kernel32.dll", "none", "OutputDebugString", "str", $msg)
EndFunc

#EndRegion


#Region Log functies

Func LogLevel()
	if $prvLogLevel = 0 Then
		$l = RegRead( "HKEY_CURRENT_USER\Software\VB and VBA Program Settings\All\Logging", "Level")
		if @error<> 0 Then
			$prvLogLevel = 1 ; Error
		Else
			Switch $l
				Case "ERROR"
					$prvLogLevel = 1 
				Case "WARNING"
					$prvLogLevel = 2
				Case "INFO"
					$prvLogLevel = 3
				Case "DEBUG"
					$prvLogLevel = 4
					
			EndSwitch
		EndIf
		;OutputDebug( "! LogLevel: " & $prvLogLevel )
	EndIf
	Return $prvLogLevel
EndFunc

Func LogMode()
	if $prvLogMode = 0 Then
		$l = RegRead( "HKEY_CURRENT_USER\Software\VB and VBA Program Settings\All\Logging", "Mode")
		if @error<> 0 Then
			$prvLogMode = 4 ; Console
		else 
			$prvLogMode = $l
		endif
		
		if BitAND($prvLogMode, 2) > 0 then
			$do_file = True
		EndIf
		if BitAND($prvLogMode, 4) > 0 then
			$do_console = True
		EndIf
		if BitAND($prvLogMode, 8) > 0 then
			$do_debugview = True
		EndIf

	EndIf
	Return $prvLogMode
EndFunc

Func LogError($msg)
	LogMode()
	if $do_console then ConsoleWrite( "! " & $msg & @CRLF)
	if $do_debugview then OutputDebugString( "[error] " & $msg & @CRLF )
EndFunc

Func LogWarning($msg)
	LogMode()
	If LogLevel() >= 2 Then
		if $do_console then ConsoleWrite( "- " & $msg & @CRLF)
		if $do_debugview then OutputDebugString( "[warning] " & $msg & @CRLF )
	EndIf
EndFunc

Func LogInfo($msg)
	LogMode()
	If LogLevel() >= 3 Then
		if $do_console then ConsoleWrite( "  " & $msg & @CRLF)
		if $do_debugview then OutputDebugString( "[info] " & $msg & @CRLF )
	EndIf
EndFunc

Func LogDebug($msg)
	LogMode()
	If LogLevel() >= 4 Then
		if $do_console then ConsoleWrite( "> " & $msg & @CRLF)
		if $do_debugview then OutputDebugString( "[debug] " & $msg & @CRLF )
	EndIf
EndFunc

Func LogBegin($msg)
	LogMode()
	if $do_console then ConsoleWrite( "+ " & StringFormat("%-100s : ",$msg) )
	$prvMsg = $msg
EndFunc

Func LogEnd($errcode=0)
	LogMode()
	$msg = "[ " & _Iif($errcode=0, "ok", "!!") & " ]"
	if $do_console then ConsoleWrite( $msg  & @CRLF)
	if $do_debugview then OutputDebugString( $prvMsg & " " & $msg & @CRLF )
EndFunc


#EndRegion

#Region test functie
Func _TestOuputDebug()
	LogWarning( "WARNING" )
	LogBegin( "Test error" )
	Sleep( 1000)
	LogEnd()
	
EndFunc


;_TestOuputDebug()

#EndRegion