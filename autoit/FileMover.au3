#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_icon=mk.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.0.0
 Author:         myName

 Script Function:
	Template AutoIt script.

#ce ----------------------------------------------------------------------------

#Include <File.au3>


; Script Start - Add your code below here
if $CmdLine[0] = 0 Then
	msgbox( 0, "FileMover", "No arguments" )
	exit
EndIf

$ini = @MyDocumentsDir & "\filemover.ini"

$fn = $Cmdline[1]

$szDrive=""
$szDir=""
$szFName=""
$ext=""

_PathSplit($fn, $szDrive, $szDir, $szFName, $ext)
$ext = StringMid( $ext, 2 )

$folder = IniRead( $ini, "folders", $ext, "" )
if $folder = "" Then
	$folder = FileSelectFolder("Where should files of type " & $ext & " be stored?", "", 7)
	if @error <> 0 then Exit
	IniWrite( $ini, "folders", $ext, $folder )
endif

if Not FileExists( $folder ) Then
	DirCreate( $folder )
EndIf	

if FileExists( $fn ) Then
	FileMove( $fn, $folder )
EndIf