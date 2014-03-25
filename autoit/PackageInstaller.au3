#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_icon=mk.ico
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


Opt("GUIOnEventMode", 1)

#include "Include\Repository.au3"
#include "Include\PackageManager.au3"
#include "Include\FileDispatcher.au3"
#include "Include\Melding.au3"

#Region Globals

Global $base_url
Global $aRecords[1]

Global $msgbox_title = "Package Installer"

; GUI elements
Global $cmbRepo
Global $lst_modules
Global $btn_go
Global $btn_rem
Global $lbl_descr

#EndRegion
;


PackageInstallerGUI()


#Region GUI

Func PackageInstallerGUI()

Local $arr

#Region ### START Koda GUI section ### Form=
	$Form1_1 = GUICreate("Package installer", 438, 485, -1, -1)
	GUISetOnEvent($GUI_EVENT_CLOSE, "Form1Close")
	$btn_go = GUICtrlCreateButton("Installeer", 30, 456, 75, 25, 0)
	GUICtrlSetOnEvent(-1, "btn_goClick")
	$btn_rem = GUICtrlCreateButton("Verwijder", 110, 456, 75, 25, 0)
	GUICtrlSetOnEvent(-1, "btn_remClick")
	$lbl_descr = GUICtrlCreateLabel("", 8, 320, 414, 113, $SS_SUNKEN)
	$lst_modules = GUICtrlCreateListView("Pakket naam|Geïnstalleerd|Beschikbaar|Beschrijving", 8, 48, 417, 233)
	GUICtrlSendMsg(-1, 0x101E, 0, 200)
	GUICtrlSendMsg(-1, 0x101E, 1, 100)
	GUICtrlSendMsg(-1, 0x101E, 2, 100)
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

	UpdatePackageList()


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

	GUICtrlSendMsg($lst_modules, $LVM_SETCOLUMNWIDTH, 3, 0)
#Region Loop
	While 1
		Sleep(100)
	WEnd
#EndRegion

EndFunc

Func UpdatePackageList()
	$iret = InetGet( $base_url & "/package_list.txt", @TempDir & "\package_list.txt" )
	if $iret = 0 Then
		Return False
	endif
	Local $dt[2][2] = [ _
		[ "^#","" ], _
		[ "^(.*)", "_entry" ] _
	]
	LogDebug("legen lijst")
	_GUICtrlListView_DeleteAllItems( $lst_modules )
	FileDispatcher( @TempDir & "\package_list.txt", $dt )
	FileDelete(@TempDir & "\package_list.txt")
	GUICtrlSendMsg($lst_modules, $LVM_SETCOLUMNWIDTH, 3, 0)
	Return True
EndFunc

Func _entry( $arr )
Dim $loc_ver, $dummy1, $dummy2, $taglist

	$package =  $arr[1]

	InetGet( $base_url & "/Packages/" & $package & ".ini", @TempDir & "\" & $package & ".ini" )
	$ver = IniRead( @TempDir & "\" & $package & ".ini", "general", "version", "" )
	$descr = IniRead( @TempDir & "\" & $package & ".ini", "general", "description", "" )

	GetPackageInfo( $package, $loc_ver, $dummy1, $dummy2, $taglist )
	ConsoleWrite( $package & " " & $descr & " " & $ver & " " & $loc_ver  & @CRLF )

	GUICtrlCreateListViewItem( $package  & "|" & $loc_ver & "|" & $ver & "|" & $descr, $lst_modules)
	GUICtrlSetOnEvent(-1, "ItemPressed")

	; clean-up
	FileDelete( @TempDir & "\" & $package & ".ini" )

EndFunc

#EndRegion



func cmbRepoChange()
	$r = _GUICtrlComboBox_GetEditText($cmbRepo)
	$old_base_url = $base_url

	if $r <> $base_url Then
		$base_url = $r
		$ok = UpdatePackageList()
		if not $ok Then
			$base_url = $old_base_url
			_GUICtrlComboBox_SelectString($cmbRepo, $base_url)

		EndIf
	EndIf
EndFunc

Func btn_goClick()
Local $arr

	$item_str = GUICtrlRead(GUICtrlRead($lst_modules))
	$arr = StringSplit( $item_str, "|" )

	GUICtrlSetState( $btn_go, $GUI_DISABLE )

 	$package = $arr[1]
	$verold = $arr[2]
	$vernew = $arr[3]
	$descr = $arr[4]


	Melding("Bezig met installeren van pakket '" & $package & "'||Even geduld a.u.b." )
	if StringStripWS( $verold, 2 ) <> "" Then
		LogInfo( "Upgrade package" )
		$ok = UpdatePackage( $package, $base_url & "/Packages" )
	Else
		$ok = InstallPackage( $package, $base_url & "/Packages" )
	EndIf
	MeldingSluiten()

	GUICtrlSetState( $btn_go, $GUI_ENABLE )
	If $ok Then
		GUICtrlSetState( $btn_go, $GUI_DISABLE )
		GUICtrlSetState( $btn_rem, $GUI_ENABLE )
		GUICtrlSetData( GUICtrlRead($lst_modules), $package & "|" &  $vernew & "|" & $vernew & "|" &  $descr )
	EndIf

EndFunc

Func btn_remClick()
	Local $arr

	$item_str = GUICtrlRead(GUICtrlRead($lst_modules))
	$arr = StringSplit( $item_str, "|" )

	GUICtrlSetState( $btn_rem, $GUI_DISABLE )

 	$package = $arr[1]
	$verold = $arr[2]
	$vernew = $arr[3]
	$descr = $arr[4]

	LogDebug( $package & " >> " & $verold )
	If StringStripWS( $verold, 2 ) ="" Then Return

	Melding("Bezig met verwijderen van pakket '" & $package & "'||Even geduld a.u.b.")
	$ok = RemovePackage( $package )
	MeldingSluiten()


	If $ok Then
		GUICtrlSetState( $btn_go, $GUI_ENABLE )
		GUICtrlSetState( $btn_rem, $GUI_DISABLE )
		GUICtrlSetData( GUICtrlRead($lst_modules), $package & "| |" & $vernew & "|" &  $descr )
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

	GUICtrlSetData( $lbl_descr, $item[4] )

	if StringStripWS( $item[2], 2 )  = "" Then
		GUICtrlSetState( $btn_go, $GUI_ENABLE )
		GUICtrlSetState( $btn_rem, $GUI_DISABLE )
	Else
		GUICtrlSetState( $btn_go, $GUI_DISABLE )
		GUICtrlSetState( $btn_rem, $GUI_ENABLE )
	EndIf
	if IsNewer( StringStripWS( $item[3], 2 ), StringStripWS( $item[2], 2 ))  Then
		GUICtrlSetState( $btn_go, $GUI_ENABLE )
	EndIf
EndFunc

#EndRegion





