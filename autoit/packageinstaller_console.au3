#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_icon=mk.ico
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include "PackageManager.au3"

if $CmdLine[0] <> 1 Then
	ConsoleWrite( "Geen argumenten opgegeven." & @CRLF )
	
	Exit
EndIf

$host_count = IniRead( @ScriptDir & "\ModuleManager.ini", "Repository", "hostcount", "1" )
$host_nr = IniRead( @ScriptDir & "\ModuleManager.ini", "Repository", "default", "1" )
$base_url = IniRead( @ScriptDir & "\ModuleManager.ini", "Repository", "host" & $host_nr, "http://www.mauricekoster.com/Modules" )


InstallPackage( $CmdLine[1], $base_url & "/Packages" )