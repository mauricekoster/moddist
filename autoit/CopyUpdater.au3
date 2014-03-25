#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_icon=mk.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include "Include\Logging.au3"

ProcessWaitClose( "Updater.exe" )

LogDebug( "Updater.exe has finished" )
;Sleep(1000)
LogDebug( "Copy Updater.exe" )
FileCopy( @TempDir & "\Updater.exe", @AppDataDir & "\Updater\Updater.exe", 1 )
if @error <> 0 Then
	LogWarning( "Kan Updater.exe niet kopieren" )
EndIf
LogDebug( "Delete temporary Updater.exe" )
FileDelete( @TempDir & "\Updater.exe" )