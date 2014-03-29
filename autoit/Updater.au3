#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_icon=mk.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <Array.au3>
#Include <File.au3>

#include "Include\ExcelAddins.au3"

#Include "Include\Logging.au3"
#Include "Include\Melding.au3"
#include "Include\UpdateModule.au3"
;#include "Include\ReplaceTags.au3"

;Global $current_version
;Global $current_url
;Global $current_build
;Global $bestand[1]
;Global $timestamp[1]
;Global $file_count
;Global $module
;Global $cur_dir
Local $x

Const $UPDATER_VERSION = "4"

LogInfo( "Updater version: " & $UPDATER_VERSION)

LogInfo( "Start updating...")
Melding( "Start bijwerken van modules...||Even geduld a.u.b.")
LogDebug( "TEMP dir: " & @TempDir )
LogDebug( "APPDATA: " & @AppDataDir & "\Updater" )


$filesearch = FileFindFirstFile( @AppDataDir & "\Updater\*.versieinfo" )
if $filesearch = -1 Then
	LogInfo("Nothing found")
	Exit
EndIf

LogInfo( "--- START UPDATING ----------------------------------------------------------------------------------------------------" )
while 1
	$f = FileFindNextFile($filesearch)
	if @error then ExitLoop

	$result = _PathSplit($f,$x,$x,$x,$x )

	$module = $result[3]

	LogDebug( "Module versioninfo: " & $module )
	if $f <> "" then UpdateModule( $module )

WEnd
MeldingSluiten()
LogInfo( "--- THE END -----------------------------------------------------------------------------------------------------------" )

