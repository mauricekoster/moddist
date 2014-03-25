#include-once

#include "FileDispatcher.au3"
#include "ReplaceTags.au3"
#Include "ExcelAddins.au3"
#Include "PackageManager.au3"
#include "Melding.au3"

Global $current_url
Global $component_name
Global $cur_dir



Func InstallModule( $modname, $url )

	LogInfo( "Install module : " & $modname & " from " & $url )

	If Not FileExists( @AppDataDir & "\Updater" ) Then
		DirCreate( @AppDataDir & "\Updater" )
	EndIf

	$the_url = $url & "/" & $modname & ".versieinfo"
	$fn = @AppDataDir & "\Updater\" & $modname  & ".versieinfo"

	LogDebug( "url: " & $the_url )
	LogDebug( "fn:" & $fn )

	$iRet = InetGet( $the_url, $fn )
	if $iRet = 0 Then

		LogError( "Problem with internet connection." )
		SetError(-1)

		FileDelete( $fn )
		Return False

	EndIf

	$regel = FileReadline( $fn, 1 )

	;OutputDebug( $regel )
	If $regel <> "# VERSIEINFO" Then

		LogError ( "Bestand is geen versie info. Bestand niet gevonden of er is een internet probleem." )
		FileDelete( $fn )
		SetError(-1)

		Return False

	EndIf


	Return ProcessFile( $modname, $fn, $url )


EndFunc


Func ProcessFile( $comp_name, $fn, $url )
Local $arr

Dim $dispatch[12][2] = [ _
		[ "^#", "" ], _
		[ "^versie:", "" ], _
		[ "^url:(.*)", "_url" ], _
		[ "^build:(.*)", "_build" ], _
		[ "^message:(.*)", "_message" ], _
		[ "^description:(.*)", "_description" ], _
		[ "^shortcut:(.*)", "_shortcut" ], _
		[ "^menu:(.*)", "_shortcut" ], _
		[ "^\*(.*)", "_package" ], _
		[ "^\[(.*)]", "_map" ], _
		[ "([^>]*)>>>([^|]*)\|?(.*)?", "_filespecial" ], _
		[ "([^:]*):(.*)", "_file" ] _
	]


    LogInfo( "Processing component: " & $comp_name )
    LogInfo( "Processing filename: " & $fn )


	$current_url = $url
	$component_name = $comp_name
    $cur_dir = @WorkingDir

	LogDebug( "Current URL: " & $current_url )
	LogDebug( "Current dir: " & $cur_dir )

	FileDispatcher( $fn, $dispatch )

	TrayTip( "", "", 0 )

	Return True

EndFunc

Func _url( $arr )
	LogDebug( $arr )
	$current_url = $arr[1]
	LogInfo( "Switching URL: " & $current_url )
EndFunc

Func _build( $arr )
	; do something
	$dummy =  ExcelAddinsFolder() & "\" &  $component_name & ".xla"
	LogInfo( "Installeer Excel-addin: " & $dummy )
	InetGet( $current_url & "/" & $component_name & ".xla", $dummy )
	InstallXLA( $dummy )
	SetExcelVBAsecurity()
EndFunc

Func _description( $arr )
	$message = $arr[1]
	LogDebug( "descr: " & $message )
	;TrayTip( "Updater - " & $component_name, $message, 10 )
	Melding3( $message )
	Sleep( 1000 )
EndFunc

Func _message( $arr )
	$message = $arr[1]
	LogInfo( "msg: " & $message )
	;TrayTip( "Updater - " & $component_name, $message, 10 )
	Melding4( $message )
	Sleep( 1000 )
EndFunc

Func _package( $arr )
	$package = $arr[1]
	LogInfo( "Install package: " & $package )
	InstallPackage( $package, $current_url )
EndFunc

Func _map( $arr )
	$mapinfo = $arr[1]
	LogDebug( "Mapmatch: " & $mapinfo )

	$__arr = StringSplit( $mapinfo, "/" )


	If $__arr[0] = 3 And FileExists( @MyDocumentsDir & "\" & $component_name  & ".ini" ) Then
		;LogDebug( "@@"  )
		$dummy = IniRead( @MyDocumentsDir & "\" & $component_name  & ".ini", $__arr[1], $__arr[2], "" )
	Else
		if $__arr[0] = 3 Then
			;LogDebug( "::" & $__arr[3] )
			$dummy = ReplaceDirTags( $__arr[3] )

		ElseIf $__arr[0] = 1 Then
			;LogDebug( "::" & $__arr[1] )
			$dummy = ReplaceDirTags( $__arr[1] )

		EndIf

	EndIf

	LogDebug( "Map: " & $dummy )

	If Not FileExists( $dummy ) Then
		DirCreate( $dummy )
	EndIf

	$cur_dir = $dummy
EndFunc

Func _file( $arr )
	$nm = $arr[1]
	$ts = $arr[2]

	If Not FileExists( $cur_dir & "\" & $nm ) Then

		LogInfo( "Bestand: " & $cur_dir & "\" & $nm &  " (" & $ts & ")" )
		$ret = InetGet( $current_url & "/" & $nm, $cur_dir & "\" & $nm )
		if $ret = 0 Then
			LogWarning( "Bestand niet gedownload. (" & $nm & ")" )
			FileDelete( $cur_dir & "\" & $nm )
		Else
			FileSetTime(  $cur_dir & "\" & $nm, $ts, 0 )
		EndIf

	EndIf

EndFunc

Func _filespecial( $arr )
Dim $dt[10][2] = [ _
		[ "{{desktop}}", 	  @DesktopDir ], _
		[ "{{windir}}", 	  @WindowsDir ], _
		[ "{{progfiles}}",    @ProgramFilesDir ], _
		[ "{{programfiles}}", @ProgramFilesDir ], _
		[ "{{mydocuments}}",  @MyDocumentsDir ] _
	]

	$nm = $arr[1]
	$to = $arr[2]
	$sep = "\"

	if UBound($arr)>2 then
		if $arr[3]<> "" then $sep = $arr[3]
	EndIf
	If FileExists( $cur_dir & "\" & $to ) Then Return

	FileReplaceTags( $cur_dir & "\" & $nm, $cur_dir & "\" & $to, $dt, $sep, False )

EndFunc

Func _shortcut( $arr )
	; shortcut:Leesmij.txt:Lees dit bestand:{{desktop}}
	LogDebug( "shortcut/menu" )

	$__arr = StringSplit( $arr[1], ":")
	$fn =  $cur_dir & "\" & $__arr[1]
	$descr = $__arr[2]
	$dir = ReplaceDirTags( $__arr[3] )
	$workdir = $cur_dir

	if $__arr[0] >3 Then
		;LogDebug( "!!!" )
		$workdir = ReplaceDirTags( $__arr[4] )
	EndIf

	if not FileExists( $dir ) Then
		DirCreate( $dir )

	EndIf

	$lnk = $dir
	If $descr<> "" Then
		$lnk = $lnk & "\" &  $descr & ".lnk"
	EndIf

	LogDebug( "  file:" & $fn )
	LogDebug( "  descr:" & $descr  )
	LogDebug( "  location:" & $lnk  )
	LogDebug( "  workdir:" & $workdir  )

	FileCreateShortcut( $fn, $lnk  , $workdir,"", $descr)
EndFunc


#EndRegion
