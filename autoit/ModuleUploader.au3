#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#Include <GuiComboBox.au3>

#include <File.au3>
#include <FTPEx.au3>

#include "Include\Logging.au3"
#include "Include\FileDispatcher.au3"
#include "Include\ReplaceTags.au3"
#include "Include\Melding.au3"
#include "Include\Repository.au3"

Global $dont_add_to_modulelist = False

Global $repo_name
Global $base_url
Global $repo_url
Global $vi_file
Global $ftp_session
Global $module_dir
Global $current_dir
Global $current_ftpdir
Global $current_url
Global $build_nr

Global $ftphost
Global $ftpuser
Global $ftppassword
Global $ftpdirectory
Global $ftpbasedirectory

Global $description

Opt("GUIOnEventMode", 1)
#Region ### START Koda GUI section ### Form=ModuleUploader.kxf
$Form1_1 = GUICreate("Module uploader", 367, 157, 364, 166)
GUISetOnEvent($GUI_EVENT_CLOSE, "Form1Close")
$Combo1 = GUICtrlCreateCombo("", 104, 16, 177, 25)
$Input1 = GUICtrlCreateInput("", 104, 56, 209, 21)
$btnSelect = GUICtrlCreateButton("...", 313, 58, 19, 17)
GUICtrlSetOnEvent(-1, "btnSelectClick")
$Label1 = GUICtrlCreateLabel("Repository:", 32, 16, 57, 17)
$Label2 = GUICtrlCreateLabel("Bestand:", 32, 56, 46, 17)
$btnUpload = GUICtrlCreateButton("Uploaden", 72, 112, 75, 25)
GUICtrlSetOnEvent(-1, "btnUploadClick")
$btnClose = GUICtrlCreateButton("Sluiten", 200, 112, 75, 25)
GUICtrlSetOnEvent(-1, "btn_sluitenClick")
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###


GUICtrlSetData( $Combo1, "" )
$host_count = RepositoryCount()
For $i = 1 to $host_count
	$repo_name = GetRepositoryName($i)
	GUICtrlSetData( $Combo1, $repo_name )
Next
_GUICtrlComboBox_SetCurSel($Combo1, 0)

While 1
	Sleep(100)
WEnd

#Region Event functies
Func btnSelectClick()
Dim $dir
Dim $module

Dim $drive
Dim $ext

	$dir = RegRead( "HKEY_CURRENT_USER\Software\MKSoft\Module Uploader", "lastdir" )
	if @error <> 0 Then
		$dir = @WorkingDir
	EndIf
	if StringRight($dir, 1) <> "\" Then
		$dir = $dir & "\"
	EndIf

	$list_bestand = FileOpenDialog( "Module uploader", $dir, "List bestand (*.list)", 3 )

	If $list_bestand = "" or @error <> 0 Then
		Return
	EndIf

	_PathSplit( $list_bestand, $drive, $module_dir, $module, $ext )
	$module_dir = $drive & $module_dir
	if $module_dir <> $dir Then
		RegWrite( "HKEY_CURRENT_USER\Software\MKSoft\Module Uploader", "lastdir", "REG_SZ", $module_dir )
	EndIf
	LogDebug( "list_bestand: " & $list_bestand )

	GUICtrlSetData( $Input1, $list_bestand )

EndFunc

Func btnUploadClick()

	$idx = _GUICtrlComboBox_GetCurSel($Combo1)
	LogDebug("Selected repo: " & $idx )

	; reset values
	$ftphost = ""
	$ftpuser = ""
	$ftppassword = ""
	$ftpbasedirectory = "/"
	; get values
	GetRepositoryFTPInfo( $idx+1, $ftphost, $ftpuser, $ftppassword, $ftpbasedirectory )
	$ftpdirectory = ""

	$repo_url = GetRepositoryURL($idx+1)

	LogDebug( "repo: " & $repo_url )
	LogDebug( "ftp: " & $ftphost )


	UploadModule()

EndFunc

Func Form1Close()
	Exit
EndFunc


Func btn_sluitenClick()
	Exit
EndFunc

#EndRegion




Func UploadModule()
Dim $dir
Dim $module
Dim $drive
Dim $ext


	#Region FASE 1
	; ---------------------------------------------------------------------------------
	;
	; Vraag om .list bestand en parse deze voor de FTP gegevens
	;
	; ---------------------------------------------------------------------------------

	LogInfo( "--- FASE 1 --------------------------------------------------------------------------------------------------------" )

	$list_bestand = GUICtrlRead( $Input1 )

	if $list_bestand = "" Then
		MsgBox(0, "ModuleUploader", "Geen bestand opgegeven." )
		Return
	EndIf

	_PathSplit( $list_bestand, $drive, $module_dir, $module, $ext )

	$module_dir = $drive & $module_dir

	LogDebug( "Module: " & $module )
	LogDebug( "Module directory: " & $module_dir )

	$base_url = $repo_url
	$build_nr = 0

	$description = "(no description)"

	Dim $fase1[4][2] = [ _
			[ "^ftp(.*):(.*)", "_ftp_1" ], _
			[ "^url:(.*)", "_url_1" ], _
			[ "^description:(.*)", "_description" ], _
			[ "^!!!DONTADDTOMODULELIST!!!", "_dontaddtomodulelist" ] _
		]

	LogDebug( "ftpbasedirectory = " & $ftpbasedirectory )
	FileDispatcher( $list_bestand, $fase1 )

	If $ftphost = "" Then
		MsgBox( 0, "Module uploader", "Geen FTP host gedefinieerd" )
		Exit
	EndIf

	if $ftpuser = "" Then
		$ftpuser = InputBox( "ModuleUploader", "Geef gebruikernaam voor " & $ftphost & ":")
		if $ftpuser = "" then Return
	EndIf
	if $ftppassword = "" Then
		$ftppassword = InputBox( "ModuleUploader", "Geef wachtwoord voor " & $ftphost & ":","","*")
		if $ftppassword = "" then Return
	EndIf

	LogDebug( "ftp: " & $ftphost & " - " & $ftpuser )
	LogDebug( "baseurl: " & $base_url )

	; zet de huidige map
	$current_dir = $module_dir
	LogDebug(  "Current dir: " & $current_dir )

	; zet huidige ftp lokatie
	$current_ftpdir = $ftpdirectory
	if $ftpbasedirectory <> "/" then $current_ftpdir = $ftpbasedirectory & $current_ftpdir
	LogDebug( "Current ftpdir: " & $current_ftpdir )

	; zet huidige URL
	if $base_url = $repo_url And $ftpdirectory <> "/" and $ftpdirectory <> "" Then
		$current_url = $base_url & $ftpdirectory
	Else
		$current_url = $base_url
	EndIf
	LogDebug( "Current URL: " & $current_url )
	LogDebug( "Description: " & $description )

	#EndRegion

	#Region FASE 2
	; ---------------------------------------------------------------------------------
	;
	; Open de FTP connectie en ga naar start lokatie
	;
	; ---------------------------------------------------------------------------------
	LogInfo( "--- FASE 2 --------------------------------------------------------------------------------------------------------" )

	$internet_session = _FTP_Open('robot')
	if $internet_session = 0 Then
		Msgbox( 0, "Module uploader" , "Kan geen FTP sessie maken." )
		Exit
	EndIf

	$ftp_session = _FTP_Connect( $internet_session, $ftphost, $ftpuser, $ftppassword )
	If $ftp_session = 0 Then
		Msgbox( 0, "Module uploader" , "Kan geen FTP connectie maken." )
		Exit
	EndIf
	LogInfo( "FTP connectie gelegd. sessieid: " & $ftp_session )

	$ok = _FTP_DirSetCurrent( $ftp_session, $current_ftpdir )
	If $ok = 0 Then
		LogDebug("Making FTP directory: " & $current_ftpdir)
		MakeFTPDirectory( $ftp_session, $current_ftpdir )
	EndIF

	; Achterhaal de huidige build nummer
	$vi = @TempDir & $module & ".versieinfo"
	$ok = _FTP_FileGet( $ftp_session, $module & ".versieinfo", $vi )
	if $ok = 0 Then
		LogWarning( "Geen versieinfo gevonden." )
	EndIf
	$build_nr = 0

	Dim $fase2[1][2] = [ ["^build:(.*)","_build_2"] ]
	If FileExists(  $vi ) Then

		FileDispatcher( $vi, $fase2 )

		FileDelete( $vi )

	EndIf


	#EndRegion

	#Region FASE 3
	; ---------------------------------------------------------------------------------
	;
	; Doorloop de .list bestand nogmaals. Dit keer worden de acties uitgevoerd.
	;
	; ---------------------------------------------------------------------------------

	LogInfo( "--- FASE 3 --------------------------------------------------------------------------------------------------------" )


	; versieinfo bestand gegevens
	$versie=@YEAR & @MON &  @MDAY & @HOUR & @MIN & @SEC

	; Genereer .versieinfo bestand
	$vi = $module_dir & $module & ".versieinfo"
	$vi_file = FileOpen( $vi, 2 )
	FileWriteLine( $vi_file, "# VERSIEINFO" )
	FileWriteLine( $vi_file, "versie:" & $versie )
	FileWriteLine( $vi_file, "url:" & $current_url )

	; Build
	$xla = $module_dir  & $module & ".xla"
	If FileExists( $xla ) Then

		if $build_nr = 0 Then
			$ret = 6
		else
			$ret = MsgBox( 4, "Module uploader" , "Nieuwe build aan maken?" )
		endif
		If $ret = 6 Then

			; upload .xla
			$dummy = $xla
			$dummy2 = $module & ".xla"
			LogInfo( "Uploading: " & $dummy )
			$ok = _FTP_FilePut($ftp_session, $dummy, $dummy2 )
			if $ok = 0 Then
				LogWarning( "Fout bij overdracht van " & $dummy )
			EndIf

			; increment build_nr
			$build_nr += 1

		EndIf
		LogDebug( "Build: " & $build_nr )

		FileWriteLine( $vi_file, "build:" & $build_nr )

	EndIf

	Melding( "Bezig met uploaden van module '" & $module & "'" )

	Dim $fase3[20][2] = [ _
			[ "^!!!DONTADDTOMODULELIST!!!", "" ], _
			[ "^#.*", "_overnemen" ], _
			[ "^;.*", "" ], _
			[ "^!(.*)", "_message" ], _
			[ "^ftp.*", "" ], _
			[ "^url:(.*)", "_url_3" ], _
			[ "([^>]*)>>>([^|]*)\|?(.*)?", "_bestandspeciaal" ], _
			[ "^\[([^:]*)]:(.*)", "_map_3_2" ], _
			[ "^(.*)\|(.*)", "_map_3_1" ], _
			[ "^\[(.*)]", "_overnemen" ], _
			[ "^message:(.*)", "_message" ], _
			[ "^description:(.*)", "_overnemen" ], _
			[ "^shortcut:(.*)", "_overnemen" ], _
			[ "^menu:(.*)", "_overnemen" ], _
			[ "^file:(.*)", "_bestand" ], _
			[ "^config:([^:]*):([^:]*):?(.*)?", "_bestandspeciaal" ], _
			[ "^\*(.*)", "_overnemen" ], _
			[ "^package:(.*)", "_overnemen" ], _
			[ "^(.*)", "_bestand" ], _
			[ "", "" ] _
		]

	FileDispatcher( $list_bestand, $fase3 )

	FileClose( $vi_file )

	#EndRegion

	#Region FASE 4

	; ---------------------------------------------------------------------------------
	;
	; Afsluiten
	;
	;
	;
	; ---------------------------------------------------------------------------------
	LogInfo( "--- FASE 4 --------------------------------------------------------------------------------------------------------" )

	$dummy = $vi
	$dummy2 = $module  & ".versieinfo"
	LogInfo( "Uploading: "  & $dummy & " -> " & $ftpbasedirectory & $ftpdirectory )
	$ok = _FTP_DirSetCurrent( $ftp_session, $ftpbasedirectory & $ftpdirectory )

	if _FTP_FilePut($ftp_session, $dummy, $dummy2 ) = 1 Then
		FileDelete( $vi )
	else
		; Fout
	EndIf

	if not $dont_add_to_modulelist Then
		LogInfo("controleren modulelist")
		if FileExists($module_dir & "\module_list.txt") Then
			FileDelete($module_dir & "\module_list.txt")
		EndIf

		$ok = _FTP_DirSetCurrent( $ftp_session, $ftpbasedirectory )
		if _FTP_FileGet($ftp_session, "module_list.txt", $module_dir & "\module_list.txt" ) = 1 Then
			LogInfo( "Module lijst opgehaald." )
		else
			; Fout, creeer een nieuwe
			LogInfo( "Module lijst niet gevonden. Een nieuwe wordt gemaakt." )
			$file_hndl = FileOpen( $module_dir & "\module_list.txt", 2 )
			FileWriteLine( $file_hndl, "# MODULELIST" )
			FileWriteLine( $file_hndl, "# Componentnaam|Beschrijving|URL" )
			FileClose( $file_hndl )

		EndIf

		$dummy = FileRead( $module_dir & "\module_list.txt" )
		If StringInStr( $dummy, @CRLF & $module & "|" ) > 0 Then
			LogInfo( "Module in lijst gevonden." )
		Else
			LogInfo( "Module niet in lijst gevonden. Toevoegen aan lijst." )
			$file_hndl = FileOpen( $module_dir & "\module_list.txt", 1 ) ; Open in append mode.
			LogDebug("Module omschrijving: " & $description )
			LogDebug( "base_url = " & $base_url )
			LogDebug("Module url:" & $ftpdirectory )
			FileWriteLine( $file_hndl, $module & "|" & $description & "|" & $ftpdirectory )
			FileClose( $file_hndl )

			LogInfo( "Uploading module_list" )
			_FTP_FilePut( $ftp_session, $module_dir & "\module_list.txt", "module_list.txt" )
		EndIf

		FileDelete( $module_dir & "\module_list.txt" )

	EndIf

	LogInfo( "--- FASE 5 *THE END* ----------------------------------------------------------------------------------------------" )

	_FTP_Close( $ftp_session )
	MeldingSluiten()

	Msgbox( 0, "Module uploader", "Gereed" )

	#EndRegion



EndFunc

; ================================================================================
;
; HULPFUNCTIES
;
; ================================================================================

Func MakeFTPDirectory( $hFTP, $dir )
	LogDebug( "Create ftp directory: " & $dir & " session: " & $hFTP )

    If  StringLeft($dir,1) = "/" Then
		LogDebug( "Set current to /" )
        _FTP_DirSetCurrent( $hFTP, "/" )
	EndIf

	$arr = StringSplit( $dir , "/" )
    For $i = 1 to $arr[0]
		if $arr[$i] = "" then ContinueLoop

        ;LogDebug( "    " & $arr[$i] )

		_FTP_DirCreate( $hFTP, $arr[$i] )

		$ok = _FTP_DirSetCurrent( $hFTP, $arr[$i] )
		if $ok  = 0 Then
			SetError(-1)
			Return
		EndIf

    Next

EndFunc

#Region Hulp Fase 1

Func _dontaddtomodulelist( $arr )
	LogDebug( "!!!DONTADDTOMODULELIST!!!" )
	$dont_add_to_modulelist = True
EndFunc


Func _ftp_1( $ftp )
	LogDebug( "ftp" & $ftp[1] & " = " & $ftp[2] )
	Switch $ftp[1]
		Case "host"
			$ftphost = $ftp[2]
		Case "user"
			$ftpuser = $ftp[2]
		Case "password"
			$ftppassword = $ftp[2]
		Case "directory"
			if $ftpdirectory="" Then
				$ftpdirectory = $ftp[2]
				if StringLeft( $ftpdirectory, 1 ) <> "/" Then
					$ftpdirectory = "/" & $ftpdirectory
				EndIf
			EndIf
	EndSwitch
EndFunc

Func _url_1( $url )
	 If $base_url = "" Then

		$base_url = $url[1]
		if StringLower(StringLeft( $base_url, 4 )) <> "http" Then
			If StringLeft( $base_url, 1 ) <> "/" then $base_url = "/" & $base_url
			$base_url = $repo_url & $base_url
		endif
		LogInfo( "base_url = " & $base_url )

	EndIf
EndFunc

Func _description( $descr )
	LogInfo( "Zet omschrijving: " & $descr[1] )
	$description = $descr[1]
EndFunc

#EndRegion

#Region Hulp fase 2

Func _build_2( $build )
	$build_nr = $build[1]
	LogInfo( "Huidige build:  " & $build_nr )
EndFunc

#EndRegion

#Region Hulp Fase 3

Func _overnemen( $arr )
	FileWriteLine( $vi_file, $arr[0] )
EndFunc

Func _url_3( $url )
	$cu = $url[1]
	if StringLower(StringLeft( $cu, 4 )) <> "http" Then
		If StringLeft( $cu, 1 ) <> "/" then $cu = "/" & $cu
		$cu = $repo_url & $cu
	endif
	if $cu <> $current_url Then
		$current_url = $cu
		LogInfo( "URL: " & $current_url )
		FileWriteLine( $vi_file, "url:" & $current_url )
	EndIf
EndFunc

Func _map_3_1( $map )
	$current_dir = ReplaceDirTags( $map[1] )
	$f = $map[2]

	if StringLeft( $f, 1 ) <> "/" Then $f = "/" & $f

	$current_ftpdir =  $f
	if $ftpbasedirectory  <> "/" Then $current_ftpdir = $ftpbasedirectory & $current_ftpdir

	LogInfo( "Current dir: " & $current_dir & "    Current ftpdir: " & $current_ftpdir )

	$ok = _FTP_DirSetCurrent( $ftp_session, $current_ftpdir )
	If @error <> 0 Then
		MakeFTPDirectory( $ftp_session, $current_ftpdir )
	EndIf
EndFunc

Func _map_3_2( $map )
	LogInfo( "map zetten" )
	LogDebug( $map[1] & ", " & $map[2] )

	If StringInStr( $map[2], "|" ) > 0 Then

		$dummy = StringSplit( $map[2], "|" )
		$current_dir = ReplaceDirTags( $dummy[1] )

		$new = $dummy[2]
		if StringLeft( $new, 1 ) <> "/" Then $new = "/" & $new

		if $ftpbasedirectory & $new <> $current_ftpdir Then

			$current_ftpdir = $new
			if $ftpbasedirectory  <> "/" Then $current_ftpdir = $ftpbasedirectory & $current_ftpdir

			$ok = _FTP_DirSetCurrent( $ftp_session, $current_ftpdir )
			If @error <> 0 Then
				MakeFTPDirectory( $ftp_session, $current_ftpdir )
			EndIf
			FileWriteLine( $vi_file, "url:" & $new )
		EndIf
	else
		$current_dir = ReplaceDirTags( $map[2] )
	EndIf

	if $current_dir = "." Then
		$current_dir = $module_dir
	EndIf

	if StringRight( $current_dir, 1 ) = "\" then $current_dir = StringTrimRight( $current_dir, 1 )

	LogInfo( "Current dir: " & $current_dir & "    Current ftpdir: " & $current_ftpdir )
	If $map[1] <> "" Then
		FileWriteLine( $vi_file, "[" & $map[1] & "]" )
	EndIf
EndFunc

Func _message( $arr )
	FileWriteLine( $vi_file, "message:" & $arr[1] )
EndFunc

Func _bestand( $arr )
	if StringStripWS( $arr[0], 3 ) = "" Then Return

	$fn = $current_dir & "\" & $arr[1]

    If FileExists( $fn ) Then

        $ts = FileGetTime( $fn, 0, 1 )
        LogDebug( "Bestand: " & $fn & ":" & $ts )

        ; Upload bestand
        LogInfo( "Uploading: " & $fn & " naar " & $arr[1] )
        if _FTP_FilePut( $ftp_session, $fn, $arr[1] ) <> 1 Then
			LogError( "Upload mislukt. (" & $fn & ")" )
		Else
			FileWriteLine( $vi_file, $arr[1] & ":" & $ts )
		EndIf
	Else
		LogWarning( "Bestand bestaat niet: " & $fn )
    EndIf
EndFunc

Func _bestandspeciaal( $arr )
	$fn = $current_dir & "\" & $arr[1]

    If FileExists( $fn ) Then

        $ts = FileGetTime( $fn, 0, 1 )
        LogDebug( "Bestand: " & $fn & ":" & $ts )

        ; Upload bestand
        LogInfo( "Uploading: " & $fn )
        if _FTP_FilePut( $ftp_session, $fn, $arr[1] ) <> 1 Then
			LogError( "Upload mislukt. (" & $fn & ")" )
		Else
			FileWriteLine( $vi_file, $arr[1] & ":" & $ts )
			;LogDebug( "#arg: " & UBound($arr) )
			if UBound($arr) >2 Then
				;LogDebug( "arg 3" )
				if $arr[3] <> "" Then
					FileWriteLine( $vi_file, $arr[1] & ">>>" & $arr[2] & "|" & $arr[3] )
				Else
					FileWriteLine( $vi_file, $arr[1] & ">>>" & $arr[2] )
				EndIf

			Else
				;LogDebug( "arg 2" )
				FileWriteLine( $vi_file, $arr[1] & ">>>" & $arr[2] )
			EndIf
		EndIf
	Else
		LogWarning( "Bestand bestaat niet: " & $fn )
    EndIf
EndFunc

#EndRegion
