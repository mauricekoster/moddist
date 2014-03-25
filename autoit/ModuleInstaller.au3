#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_icon=mk.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <ButtonConstants.au3>
#include <GUIConstantsEx.au3>
#include <ListViewConstants.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <GUIComboBox.au3>
#include <GuiListView.au3>
#include <File.au3>

#include "Include\Logging.au3"
#include "Include\Melding.au3"
#include "Include\InstallModule.au3"
#include "Include\Repository.au3"

Opt("GUIOnEventMode", 1)

#Region Globals

Global $base_url
Global $aRecords[1]

Global $msgbox_title = "Module Installer"

; GUI elements
Global $cmbRepo
Global $lst_modules
Global $btn_go
Global $module_list
Global $lbl_descr

#EndRegion
;


ModuleInstallerGUI()



#Region GUI

Func ModuleInstallerGUI()

Local $arr

#Region ### START Koda GUI section ### Form=ModuleInstaller.kxf
	$Form1_1 = GUICreate("Module installer", 438, 485, -1, -1)
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


#Region Installatie van bestanden
	If not FileExists( @ScriptDir & "\unzip.exe" ) Then

		FileInstall( "unzip.exe", @ScriptDir & "\unzip.exe" )

	EndIf
#EndRegion
;


	$host_count = RepositoryCount()
	if $host_count > 0 Then
		$host_nr = GetDefaultRepositoryNr()
		$base_url = GetRepositoryURL($host_nr)
	Else
		$host_nr = 0
		$base_url = "http://www.mauricekoster.com/Modules"
	EndIf
	LogDebug( "Repository: " & $base_url )

	UpdateModuleList()


	if $host_count > 1 Then
		GUICtrlSetState( $lblRepo, $GUI_SHOW )
		GUICtrlSetState( $cmbRepo, $GUI_SHOW )

		GUICtrlSetData( $cmbRepo, "" )
		For $i = 1 to $host_count
			$a = GetRepositoryName($i)
			GUICtrlSetData( $cmbRepo, $a )
		Next

		_GUICtrlComboBox_SetCurSel($cmbRepo, 0)

	Else
		GUICtrlSetPos( $lst_modules, 8, 16, 417,265 )

	EndIf

	; Dirty hack
	GUICtrlSendMsg($lst_modules, $LVM_SETCOLUMNWIDTH, 2, 0)
	GUICtrlSendMsg($lst_modules, $LVM_SETCOLUMNWIDTH, 3, 0)

#Region Loop
	While 1
		Sleep(100)
	WEnd
#EndRegion

EndFunc


Func UpdateModuleList()
	LogInfo("Update Module List")

	$module_url = $base_url & "/module_list.txt"

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


	_GUICtrlListView_DeleteAllItems($lst_modules)
	LogDebug( "Items in list:" )
	For $x = 1 to $aRecords[0]
		$current_line = $aRecords[$x]
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

	$ok = UpdateModuleList()
	if not $ok Then
		$base_url = $old_base_url
		_GUICtrlComboBox_SelectString($cmbRepo, $base_url)

	EndIf

EndFunc

Func btn_goClick()
Local $arr

	$item_str = GUICtrlRead(GUICtrlRead($lst_modules))
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

#EndRegion
