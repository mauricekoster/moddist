#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_icon=mk.ico
#AutoIt3Wrapper_outfile=abctoolbar_installer.exe
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include "Include\InstallModule.au3"
#include "Include\Melding.au3"
#include "Include\Logging.au3"
#include "Include\Repository.au3"

$modname = "ABCToolbar"

$host_count=RepositoryCount()
$base_url = "http://www.mauricekoster.com/Modules"
$host_nr = GetDefaultRepositoryNr()
if $host_nr>0 Then
	$base_url = GetRepositoryURL($host_nr)
EndIf
LogDebug( "baseurl: " & $base_url )

if not FileExists( @AppDataDir & "\Updater\Updater.versieinfo" ) Then
	InstallModule( "Updater", $base_url  )

	; regentry run zetten
	RegWrite( "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", "Updater", "REG_SZ", '"' & @AppDataDir & '\Updater\Updater.exe"' )

endif

$module_url = $base_url & "/module_list.txt"

$temp_dir = @TempDir
$module_list = $temp_dir & "\module_list.txt"

$iRet = InetGet( $module_url, $module_list )
if $iRet = 0 Then
	MsgBox( 48, "Installer", "Kan geen verbinding maken met " & $base_url )
	Exit(1)
EndIf

$file = FileOpen( $module_list, 0 )
if @error <> 0 Then Exit(1)

While 1
	$found = False
	$line = FileReadLine( $file )
	if @error <> 0 Then ExitLoop

	$found = True
	$arr = StringSplit( $line, "|" )

	if $arr[1] = $modname Then Exitloop

WEnd

if not $found Then Exit(1)

Melding( "Installeren van module '" & $modname & "'||Even geduld a.u.b.")
InstallModule( $modname, $base_url & "/" & $arr[3] )
MeldingSluiten()
