#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_icon=mk.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <Array.au3>
#Include <File.au3>

#include "ExcelAddins.au3"

#Include "Logging.au3"
#Include "Melding.au3"
#include "FileDispatcher.au3"
#include "ReplaceTags.au3"

Global $current_version
Global $current_url
Global $current_build
Global $bestand[1]
Global $timestamp[1]
Global $file_count
Global $module
Global $cur_dir
Global $addin_path

Func UpdateModule($module)
Local $file, $filename

	$addin_path = ExcelAddinsFolder()
	LogDebug( "ADDINPATH: " & $addin_path )

	$filename = $module & ".versieinfo"
	LogBegin( "Processing module: " & $module )

	Melding3( "Controleren van module '" & $module & "'" )
	Melding4( "" )
	LogInfo( "Component: " & $module )

    $current_url = ""
	$cur_dir = @ScriptDir

	$file_count = 0

	Global $bestand[ 1 ]



Dim $dt1[12][2] = [ _
		[ "^#", "" ], _
		[ "^versie:(.*)", "_versie1" ], _
		[ "^description:(.*)", "_description" ], _
		[ "^url:(.*)", "_url1" ], _
		[ "^build:(.*)", "_build1" ], _
		[ "^message:(.*)", "" ], _
		[ "^menu:(.*)", "" ], _
		[ "^shortcut:(.*)", "" ], _
		[ "^\*(.*)", "" ], _
		[ "^\[(.*)]", "" ], _
		[ "([^>]*)>>>(.*)", "" ], _
		[ "([^:]*):(.*)", "_file1" ] _
	]

	$fn = @AppDataDir & "\Updater\" & $filename
	FileDispatcher( $fn, $dt1 )


	$fn = @TempDir & "\" & $filename
	LogInfo( "Downloading: " & $current_url & "/" & $filename &  "--> " &  $fn )
	$iRet = InetGet(  $current_url & "/" & $filename, $fn )
	If $iRet=0 Then
		LogError( "Bestand niet gevonden op URL: " & $current_url & "/" & $filename  )
		Return
	EndIf

	$no_change = 0

	;_ArrayDisplay( $bestand )

Dim $dt2[12][2] = [ _
		[ "^#", "" ], _
		[ "^description:(.*)", "_update_description" ], _
		[ "^versie:(.*)", "_versie2" ], _
		[ "^url:(.*)", "_url2" ], _
		[ "^build:(.*)", "_build2" ], _
		[ "^message:(.*)", "_message2" ], _
		[ "^menu:(.*)", "" ], _
		[ "^shortcut:(.*)", "" ], _
		[ "^\*(.*)", "" ], _
		[ "^\[(.*)]", "_map2" ], _
		[ "([^>]*)>>>(.*)", "" ], _
		[ "([^:]*):(.*)", "_file2" ] _
	]


	FileDispatcher( $fn, $dt2 )

	FileMove(  @TempDir & "\" & $filename, @AppDataDir & "\Updater\" & $filename, 1 )
	FileDelete( @TempDir & "\" & $filename )

	LogEnd( )

EndFunc

func _update_description( $arr )
	LogDebug( "Beschrijving: " & $arr[1] )
	Melding4( $arr[1] )
EndFunc

Func _versie1( $arr )
	$current_version = $arr[1]
	LogDebug( "Versie: " & $current_version )
EndFunc

func _url1( $arr )
	If $current_url = "" Then

		$current_url = $arr[1]
		LogDebug( "URL: " & $current_url )

	EndIf
EndFunc

func _build1( $arr )
	$current_build = Number($arr[1])
	LogDebug( "Build: " & $current_build )
EndFunc

func _file1( $arr )
	; entry is een bestand

	$nm = $arr[1]
	$ts = $arr[2]

	LogDebug( $nm & "::" & $ts )
	_ArrayAdd( $bestand, $nm )
	_ArrayAdd( $timestamp, $ts )

	$file_count += 1
EndFunc

Func _versie2( $arr )
	$new_version = $arr[1]
	LogDebug( "Nieuw versie: " & $new_version )
	If $new_version = $current_version Then

		LogInfo( $module & " is up-to-date" )
		$no_change = 1
		SetError(-1)

	EndIf
EndFunc

Func _url2( $arr )
	$current_url = $arr[1]
	LogDebug( "Switching URL: " & $current_url )
EndFunc

func _build2( $arr )

	$new_build = Number($arr[1])
	LogDebug( "Nieuwe build: " & $new_build )
	if $current_build < $new_build Then

		$dummy = $addin_path & "\" & $module & ".xla"

		LogDebug( "Installeer Excel-addin: " & $dummy )
		$iRet = InetGet( $current_url & "/" & $module & ".xla", $dummy )
		if $iRet = 0 Then
			LogWarning("Excel Addin niet gevonden (" & $dummy & ")" )
			Return
		EndIf
		InstallXLA( $dummy )

	EndIf
EndFunc

func _message2( $arr )
	$message = $arr[1]
	Melding4( $message )
	Sleep( 1000 )
endfunc

func _map2( $arr )

	$mapinfo = $arr[1]
	if StringInStr( $mapinfo, "/" ) > 0  Then

		$arr = StringSplit( $mapinfo, "/" )
		LogDebug( "Mapmatch: " & $mapinfo )

		If FileExists( @MyDocumentsDir & "\" & $module & ".ini" ) Then
			$dummy = IniRead( @MyDocumentsDir & "\" & $module & ".ini", $arr[1], $arr[2], "" )
		Else

			$dummy = $arr[3]

		EndIf

	Else

		$dummy = $mapinfo

	EndIf

	LogDebug( "dummy: " & $dummy )

	$dummy = ReplaceDirTags( $dummy )

	LogInfo( "InstallDir: " & $dummy )

	If Not FileExists( $dummy ) Then

		DirCreate( $dummy )

	EndIf
	$cur_dir = $dummy

EndFunc

func _file2( $arr )

	$nm = $arr[1]
	$ts = $arr[2]
	LogDebug( $nm & ":" & $ts )

	$found = false

	for $xx = 1 to $file_count

		$bestand_nm = $bestand[$xx]
		$bestand_ts = $timestamp[$xx]

		If $bestand_nm = $nm Then

			;OutputDebug( "Check " & $bestand_nm )
			$found = true
			ExitLoop

		EndIf
	Next
	;OutputDebug( $found )

	if not $found Then

		LogDebug(  "Nieuw " & $nm )
		$iRet = InetGet( $current_url & "/" & $nm, $cur_dir & "\" & $nm )
		if $iRet = 0 Then
			LogWarning( "Probleem met downloaden van " & $nm )
		Endif

	Else

		If Not FileExists( $cur_dir & "\" & $nm ) Then

			LogDebug( "Missing " & $bestand_nm )
			$iRet = InetGet( $current_url & "/" & $nm, $cur_dir & "\" & $nm )
			if $iRet = 0 Then
				LogWarning( "Probleem met downloaden van " & $nm )
			Endif

		Else

			LogDebug( $bestand_ts & " < " & $ts & " ?" )
			If $bestand_ts < $ts then

				LogDebug( "Updating " & $bestand_nm & " (" & $nm & ")" )
				LogInfo ( "Downloading: " & $current_url & "/" & $nm )
				if StringLower($nm) = "updater.exe" Then
					LogDebug ("*selfupdate")
					LogInfo( "to:" & @TempDir & "\" & $nm)

					$iRet = InetGet( $current_url & "/" & $nm, @TempDir & "\" & $nm )
					if @error = 0 Then
						FileSetTime( @TempDir & "\" & $nm, $ts )
						If FileExists( @ScriptDir & "\CopyUpdater.exe" ) Then
							LogDebug( "** starting CopyUpdater.exe **" )
							ShellExecute( @ScriptDir & "\CopyUpdater.exe", "", @AppDataDir, "", @SW_HIDE )
						EndIf
					Else
						LogWarning( "Probleem met downloaden van " & $nm )
					EndIf
				Else
					LogInfo( "to:" & $cur_dir & "\" & $nm)
					$iRet = InetGet( $current_url & "/" & $nm, $cur_dir & "\" & $nm )
					if @error <> 0 Then

						LogWarning( "Probleem met downloaden van " & $nm )
					EndIf
				Endif

			EndIf

		EndIf
	EndIf

	If FileExists( $cur_dir & "\" & $nm ) Then
		FileSetTime( $cur_dir & "\" & $nm, $ts )
	EndIf

EndFunc
