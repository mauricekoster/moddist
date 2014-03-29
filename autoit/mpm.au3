#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_icon=mk.ico
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <ButtonConstants.au3>
#include <GUIConstantsEx.au3>
#include <ListViewConstants.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <GUIComboBox.au3>
#include <GuiListView.au3>

#include <File.au3>
#include <Array.au3>
#include <String.au3>


#include "Include\Logging.au3"
#include "Include\Melding.au3"
#include "Include\InstallModule.au3"
#include "Include\Repository.au3"
#include "Include\ModuleManagement.au3"

Opt("GUIOnEventMode", 1)

#Region Globals

Global $base_url
Global $aRecords[1]

Global $APP_NAME = "Maurice Package Manager"
Global $APP_VERSION = "0.1"

; GUI elements
Global $cmbRepo
Global $lst_modules
Global $btn_go
Global $module_list
Global $lbl_descr

#EndRegion
;

;
; Maurice Package Manager
;

#Region Installatie van bestanden
If not FileExists( @ScriptDir & "\unzip.exe" ) Then
	FileInstall( "unzip.exe", @ScriptDir & "\unzip.exe" )
EndIf
#EndRegion

Local $descr, $url

$host_count = RepositoryCount()
if GetDefaultRepositoryNr() == 0 Then
	$base_url = "http://www.mauricekoster.com/Modules"
Else
	$base_url = GetDefaultRepositoryUrl()
EndIf

if $CmdLine[0]==0 Then
	ModuleInstallerGUI()

ElseIf $CmdLine[1] = 'help' Then
	help()

ElseIf $CmdLine[1] = "repo" Then
	LogInfo( "repo:" )
	$Ret = GetRepositoryList()
	$def_repo = GetDefaultRepositoryNr()

	Switch $CmdLine[2]
		case "list"
			RepoList( $Ret, $def_repo )

		case Else
			LogError("Unknown subcommand")

	EndSwitch

ElseIf $CmdLine[1] = "module" Then
	LogInfo( "module:" )
	$Ret = GetModuleList($base_url)


	Switch $CmdLine[2]
		case "list"
			println("List")
			println(_StringRepeat("=", 60) )

			for $i = 1 to $Ret[0]

				$L = StringSplit($Ret[$i], "|", 1)
				println( StringFormat(" %-20s", $L[1]) & "- " & $L[2] )
			Next
			println(_StringRepeat("=", 60) & @CRLF)

		case "install"
			if $CmdLine[0] <> 3 Then
				LogError("Invalid number of arguments")
			Else
				$modname = $CmdLine[3]
				if GetModuleInfo( $Ret, $modname, $descr, $url ) Then

					LogInfo(  "descr: " & $descr )
					LogInfo(  "url: " & $url )

					println( "Installing module '" & $modname )
					println("Please wait...")
					if StringLeft($url, 1) <> "/" Then
						$url = "/" & $url
					EndIf
					InstallModule( $modname, $base_url & $url )
					println("Done.")
				Else
					LogError("Unknown module name: " & $modname )
				EndIf
			EndIf

		case Else
			LogError("Unknown subcommand")

	EndSwitch

Else
	LogError( "Unknown command: " & $CmdLine[1] )
	help()
EndIf

#region Helper functions
Func println($msg="")
	ConsoleWrite( $msg & @CRLF )
EndFunc

Func printline( $line = "-" )
	println( _StringRepeat($line, 79) )
EndFunc
#endregion

#region Help

Func help()
	println( "Usage:" )
	println("mpm <command> [<subcommands>...]")
	println()
	println( "Current repository: " & GetDefaultRepositoryName() )
	printline("=")
	println("Commands:")
	println()
	println("help")
	println("  this help screen")
	println()
	println("repo")
	println(" - list : list of available repositories")
	println()
	println("module")
	println(" - list : list of available modules on active repository")
EndFunc


#endregion


#region Repository functions

Func RepoList($repo_list, $def)

	println("Repository name(s):")
	println( StringFormat(" Nr  %-25s %-45s%-3s",  "Name", "URL", "Def")  )
	println(_StringRepeat("=", 79) )
	for $i = 1 to $repo_list[0]
		if $i = $def then
			$extra = "(*)"
		Else
			$extra=""
		EndIf

		$L = StringSplit($Ret[$i], "|", 1)
		println( StringFormat("[%2d] %-25s %-45s%-3s", $i, $L[1], $L[2], $extra)  )
	Next
	println(_StringRepeat("=", 79) & @CRLF)

EndFunc

#endregion
















#region GUI

Func ModuleInstallerGUI()

Local $arr

#Region ### START Koda GUI section ### Form=mpm_mainwindow.kxf
	$Form1_1 = GUICreate($APP_NAME, 438, 485, -1, -1)
	GUISetOnEvent($GUI_EVENT_CLOSE, "Form1Close")
	$btn_go = GUICtrlCreateButton("GO", 104, 456, 75, 25, 0)
	GUICtrlSetOnEvent(-1, "btn_goClick")
	$lbl_descr = GUICtrlCreateLabel("", 8, 320, 414, 113, $SS_SUNKEN)
	$lst_modules = GUICtrlCreateListView("Component naam|Geïnstalleerd?|Beschrijving|URL", 8, 48, 417, 233)
	GUICtrlSendMsg(-1, 0x101E, 0, 300)
	GUICtrlSendMsg(-1, 0x101E, 1, 100)
	GUICtrlSendMsg(-1, 0x101E, 2, 0)
	GUICtrlSendMsg(-1, 0x101E, 3, 0)
	$Label1 = GUICtrlCreateLabel("Beschrijving:", 8, 296, 64, 17)
	$btn_sluiten = GUICtrlCreateButton("Sluiten", 248, 456, 75, 25, 0)
	GUICtrlSetOnEvent(-1, "btn_sluitenClick")
	$cmbRepo = GUICtrlCreateCombo("cmbRepo", 72, 16, 353, 25)
	GUICtrlSetOnEvent(-1, "cmbRepoChange")
	GUICtrlSetState(-1, $GUI_HIDE)
	$lblRepo = GUICtrlCreateLabel("Repository:", 8, 16, 57, 17)
	GUICtrlSetState(-1, $GUI_HIDE)
	GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

	$aList = GetModuleList($base_url)
	UpdateModuleList($aList)

	if $host_count > 1 Then
		GUICtrlSetState( $lblRepo, $GUI_SHOW )
		GUICtrlSetState( $cmbRepo, $GUI_SHOW )

		GUICtrlSetData( $cmbRepo, "" )
		For $i = 1 to $host_count
			$a = GetRepositoryName($i)
			GUICtrlSetData( $cmbRepo, $a )
		Next

		_GUICtrlComboBox_SetCurSel($cmbRepo, GetDefaultRepositoryNr()-1)

	Else
		GUICtrlSetPos( $lst_modules, 8, 16, 417,265 )

	EndIf

	; Dirty hack
	GUICtrlSendMsg($lst_modules, $LVM_SETCOLUMNWIDTH, 2, 0)
	GUICtrlSendMsg($lst_modules, $LVM_SETCOLUMNWIDTH, 3, 0)

	While 1
		Sleep(100)
	WEnd

EndFunc


Func UpdateModuleList($aList)

	_GUICtrlListView_DeleteAllItems($lst_modules)
	LogDebug( "Items in list:" )
	For $x = 1 to $aList[0]
		$current_line = $aList[$x]
		if StringStripWS( $current_line, 3 ) <> "" Then
			if StringLeft($current_line, 1) <> "#" Then
				$arr = StringSplit( $current_line, "|" )
				$inst = "Nee"
				If FileExists( @AppDataDir & "\Updater\" & $arr[1] & ".versieinfo" ) Then
					$inst = "Ja"
				EndIf
				LogDebug( $arr[1] )
				GUICtrlCreateListViewItem( $arr[1] & "|" & $inst & "|" & $arr[2] & "|" & $arr[3], $lst_modules)
				GUICtrlSetOnEvent(-1, "ItemPressed")

			EndIf
		EndIf
	Next

	; Dirty hack
	GUICtrlSendMsg($lst_modules, $LVM_SETCOLUMNWIDTH, 2, 0)
	GUICtrlSendMsg($lst_modules, $LVM_SETCOLUMNWIDTH, 3, 0)

	Return True

EndFunc

#EndRegion

#Region Event Handlers

func cmbRepoChange()
	$i = _GUICtrlComboBox_GetCurSel($cmbRepo)+1
	LogDebug( "index: "  & $i )
	$r = GetRepositoryURL($i)
	LogDebug( "baseurl: "  & $base_url )
	LogDebug( "url: "  & $r )

	$old_base_url = $base_url
	$base_url = $r

	$aList = GetModuleList($base_url)
	$ok = UpdateModuleList($aList)
	if not $ok Then
		$base_url = $old_base_url
		_GUICtrlComboBox_SelectString($cmbRepo, $base_url)

	EndIf

EndFunc

Func btn_goClick()
Local $arr

	$item_str = GUICtrlRead(GUICtrlRead($lst_modules))
	LogDebug("?" & $item_str)
	if $item_str == 0 Then
		Return
	EndIf

	$arr = StringSplit( $item_str, "|" )

	GUICtrlSetState( $btn_go, $GUI_DISABLE )

	$dummy = $arr[1]
	$url = $arr[4]
	if StringLower(StringLeft( $url, 4 )) <> "http" Then
		$u = $url
		if StringLeft( $u, 1 ) <> "/" Then $u = "/" & $u
		$url = $base_url & $u
	endif

	If $arr[2] = "Ja" Then
		$ret = MsgBox( 4 + 32 + 256, $msgbox_title, "Module al geïnstalleerd. Wilt u deze opnieuw installeren?" )
		If $ret <> 6 Then
			GUICtrlSetState( $btn_go, $GUI_ENABLE )
			Return
		EndIf
	EndIf

	Melding("Bezig met installeren van module " & $dummy & "||Even geduld a.u.b." )
	$ok = InstallModule( $dummy, $url )
	MeldingSluiten()

	GUICtrlSetState( $btn_go, $GUI_ENABLE )
	If $ok Then
		GUICtrlSetData( GUICtrlRead($lst_modules), $arr[1] & "|Ja|" & $arr[3] & "|" &  $arr[4] )
	EndIf

EndFunc


Func Form1Close()
	Exit
EndFunc


Func btn_sluitenClick()
	Exit
EndFunc


Func ItemPressed()
	$item_str = GUICtrlRead(GUICtrlRead($lst_modules))
	$item = StringSplit( $item_str, "|" )

	GUICtrlSetData( $lbl_descr, $item[3] )

EndFunc


#endregion