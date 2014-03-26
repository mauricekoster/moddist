#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#Include <GuiComboBox.au3>

#include "UserSettings.au3"

Local $__ini_repo = ""

Func __getininame()

	If $__ini_repo = "" Then
		$__ini_repo = SettingsFolder() & "\Repositories.ini"
		if not FileExists( $__ini_repo ) Then
			$__ini_repo = @ScriptDir & "\Repositories.ini"
		EndIf
		;ConsoleWrite( "repo ini: " & $__ini_repo & @CRLF )
	EndIf

	Return $__ini_repo

EndFunc


Func RepositoryCount()
	$host_count = Number(IniRead( __getininame(), "Repository", "hostcount", "0" ))

	Return $host_count
EndFunc

Func SelectRepository()
	$host_count = RepositoryCount()
	if $host_count <= 1 Then
		$repo_nr = 1
		Return
	EndIf

	#Region ### START Koda GUI section ### Form=
	$frmRepoSelect = GUICreate("Selecteer repository", 388, 101, 311, 115)
	$cmbRepo = GUICtrlCreateCombo("cmbRepo", 24, 16, 337, 25)
	$btnOK = GUICtrlCreateButton("OK", 152, 56, 75, 25, 0)
	GUICtrlSetData( $cmbRepo, "" )
	For $i = 1 to $host_count
		$a = IniRead( __getininame(), "Repo" & $i, "naam" , "(leeg)" )
		GUICtrlSetData( $cmbRepo, $a )
	Next

	$d = Number(IniRead( __getininame(), "Repository", "default", "1" )) - 1
	_GUICtrlComboBox_SetCurSel($cmbRepo, $d)

	GUISetState(@SW_SHOW)
	#EndRegion ### END Koda GUI section ###

	While 1
		$msg = GUIGetMsg()
		Select
			Case $msg = $GUI_EVENT_CLOSE
				Exit

			Case $msg = $btnOK
				$repo_nr = _GUICtrlComboBox_GetCurSel($cmbRepo) + 1
				ExitLoop

		EndSelect
	WEnd
	GUIDelete()

	Return $repo_nr

EndFunc

Func GetRepositoryFTPInfo($repo_nr, byref $host, byref $user, byref $passwd, byref $basedir )
	$host_count = RepositoryCount()
	if $host_count = 0 then Return
	$ini = __getininame()
	if $repo_nr > 0 then
		$host    = IniRead( $ini, "Repo" & $repo_nr, "host", "" )
		$user    = IniRead( $ini, "Repo" & $repo_nr, "user", "" )
		$passwd  = IniRead( $ini, "Repo" & $repo_nr, "password", "" )
		$basedir = IniRead( $ini, "Repo" & $repo_nr, "basedir", "" )
	EndIf

EndFunc

func GetDefaultRepositoryUrl()
	$nr = GetDefaultRepositoryNr()
	Return GetRepositoryURL( $nr )
EndFunc

Func GetDefaultRepositoryName()
	$nr = GetDefaultRepositoryNr()
	Return GetRepositoryName( $nr )
EndFunc

func GetDefaultRepositoryNr()
	$host_count = RepositoryCount()
	if $host_count = 0 then Return 0

	Return Number(IniRead( __getininame(), "Repository", "default", "1" ))
EndFunc

Func GetRepositoryURL($repo_nr)
	$host_count = RepositoryCount()
	if $host_count = 0 then Return ""

	if $repo_nr > 0 then
		Return IniRead( __getininame(), "Repo" & $repo_nr, "url", "" )
	Else
		Return ""
	EndIf
EndFunc


Func GetRepositoryName($repo_nr)
	$host_count = RepositoryCount()
	if $host_count = 0 then Return ""

	if $repo_nr > 0 then
		Return IniRead( __getininame(), "Repo" & $repo_nr, "naam", "" )
	Else
		Return ""
	EndIf
EndFunc

Func GetRepositoryList()
	$count = RepositoryCount()
	Dim $aList[$count+1]
	$aList[0] = $count

	for $i = 1 to $count
		$aList[$i] = GetRepositoryName( $i ) & "|" & GetRepositoryURL( $i )
	Next

	Return $aList
EndFunc

;ConsoleWrite( "Repo count: " & RepositoryCount() & @CRLF )
