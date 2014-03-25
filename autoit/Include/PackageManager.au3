#include-once

#include "Logging.au3"
#include "Melding.au3"
#include <SQLite.au3>
#include <SQLite.dll.au3>

#Region Package Database

Local $initialized = False
Global Const $PACKAGE_DB_VERSION = 2
; 2- added taglist

Func MetaGet( $key )
Dim $aRow

	$retval = _SQLite_QuerySingleRow(-1,"SELECT value FROM META WHERE key='" & 'dbversion' & "' LIMIT 1;",$aRow)

	if $aRow[0] = "" Then ; Not found
		LogError( "Geen metainfo gevonden voor '" & $key & "'" )
		SetError(-1)
		Return ""
	EndIf
	LogDebug( "metaget: key=" & $key & ", value: " & $aRow[0] )
	Return $aRow[0]

EndFunc

Func MetaSet( $key, $value )

	_SQLite_Exec(-1, "UPDATE meta SET value='" & $value & "' WHERE key='" & $key & "';" )

EndFunc

Func UpgradeDatabase($curversion)
	If Not IsNewer($PACKAGE_DB_VERSION, $curversion) Then Return

	LogInfo( "Upgrading database from version " & $curversion & " to " & $PACKAGE_DB_VERSION )
	if $curversion = 1 Then
		; Upgrade to version 2
		_SQLite_Exec(-1, "ALTER TABLE packages ADD COLUMN taglist;" )
		$curversion += 1

	EndIf
	if $curversion = 2 Then
		; Upgrade to version 3

		$curversion += 1
	EndIf

	; ...

	MetaSet( "dbversion", $PACKAGE_DB_VERSION )
	; -= Done when $curversion eq. $PACKAGE_DB_VERSION =-

EndFunc

func _init_packagemanager()
	Dim $aResult, $iRows, $iColumns

	_SQLite_Startup ()
	LogInfo("_SQLite_LibVersion=" &_SQLite_LibVersion() )
	If Not FileExists( @AppDataDir & "\Updater" ) Then
		DirCreate(@AppDataDir & "\Updater")
	EndIf
	_SQLite_Open ( @AppDataDir & "\Updater\package.db" )

	$iRval = _SQLite_GetTable (-1, "PRAGMA table_info(packages);", $aResult, $iRows, $iColumns)
	;LogDebug( "init: " & $iRows )
	If $iRows = 0 Then
		LogInfo( "packages tabel maken" )
		_SQLite_Exec(-1, "CREATE TABLE packages (name, version, checkfile, removecmd);" )
	endif

	$iRval = _SQLite_GetTable (-1, "PRAGMA table_info(meta);", $aResult, $iRows, $iColumns)
	;LogDebug( "init: " & $iRows )
	If $iRows = 0 Then
		LogInfo( "meta tabel maken" )
		_SQLite_Exec(-1, "CREATE TABLE meta (key, value);" )
		_SQLite_Exec(-1, "INSERT INTO meta VALUES ('dbversion', " & $PACKAGE_DB_VERSION & ");" )
	endif

	$dbver = MetaGet( "dbversion" )

	UpgradeDatabase($dbver)

	$initialized = True
EndFunc

#EndRegion

#Region PackageInfo

Func SetPackageInfo( $name, $version, $checkfile, $removecmd, $taglist )
Dim $v, $r	, $c, $t

	if not $initialized Then
		_init_packagemanager()
	EndIf

	if GetPackageInfo($name, $v, $c, $r, $t) Then
		_SQLite_Exec(-1, "UPDATE packages SET version='" & $version & "', checkfile='" & $checkfile & "', removecmd='" & $removecmd & "', taglist='" & $taglist & "' WHERE NAME='" & $name & "';" )
	Else
		_SQLite_Exec(-1, "INSERT INTO packages (name, version, checkfile, removecmd, taglist) VALUES ('" & $name & "', '" & $version & "', '" & $checkfile & "', '" & $removecmd& "', '" & $taglist & "' );" )
	EndIf

EndFunc

Func GetPackageInfo( $name, byref $version, byref $checkfile, byref $removecmd, byref $taglist )
Dim $aRow

	if not $initialized Then
		_init_packagemanager()
	EndIf

	$retval = _SQLite_QuerySingleRow(-1,"SELECT NAME, VERSION, CHECKFILE, REMOVECMD, TAGLIST FROM packages WHERE NAME='" & $name & "' LIMIT 1;",$aRow)

	if $aRow[0] = "" Then ; Not found
		SetError(-1)
		Return False
	else
		$version = $aRow[1]
		$checkfile = $aRow[2]
		$removecmd = $aRow[3]
		$taglist = $aRow[4]
		Return True
	endif

EndFunc

Func DelPackageInfo( $name )


	if not $initialized Then
		_init_packagemanager()
	EndIf

	_SQLite_Exec(-1, "DELETE FROM packages WHERE name='" & $name & "';" )

EndFunc

#EndRegion

#Region Hulp functies

Func IsNewer( $newversion, $oldversion )
	$arr_new = StringSplit( $newversion, "." )
	$arr_old = StringSplit( $oldversion, "." )

	$idx = 1
	do
		if $arr_new[$idx] > $arr_old[ $idx ] Then
			Return True
		EndIf

		$idx += 1

		if $arr_new[0] = $arr_old[0] and $arr_new[0] < $idx Then Return False

		if $arr_new[0] < $arr_old[0] and $arr_new[0] < $idx Then Return False

		if $arr_new[0] > $arr_old[0] and $arr_old[0] < $idx Then Return True
	until false
	Return False
EndFunc

#EndRegion

#Region Package management

Func InstallPackage( $package, $url )
; package: naam van package, De gerelateerde zipbestand bevat de installer
; url: locatie van op te halen pakket
Dim $loc_ver, $loc_remcmd, $loc_cf, $tag_list

    $progfiles = @ProgramFilesDir

    If Not FileExists( @ScriptDir & "\unzip.exe" ) Then

        LogError(  "unzip.exe niet in " & @ScriptDir & " aanwezig" )
        Melding4( "unzip.exe niet in " & @ScriptDir & " aanwezig" )
        Return

	EndIf

	$ini = @TempDir & "\" & $package & ".ini"
    $iRet = InetGet( $url & "/" & $package & ".ini", $ini )
	if $iRet = 0 Then
		LogError( "Iets fout gegaan bij downloaden van package info." )
		Melding4( "Iets fout gegaan bij downloaden van package info." )
		Return
	endif

	$packagezip = IniRead( $ini, "install", "package", "-" )
	If $packagezip = "-" Then
		$packagezip = $package & ".zip"
	EndIf
	$package_version = IniRead( $ini, "general", "version", "-" )

	GetPackageInfo( $package, $loc_ver, $loc_cf, $loc_remcmd, $tag_list )

	If $loc_ver <> "" And Not IsNewer($package_version, $loc_ver) Then
		LogInfo( "recentere versie van package bestaat al." )
		Melding4( "recentere versie van package bestaat al." )
		Return
	EndIf

	$checkfile = IniRead( $ini, "install", "checkfile", "-" )
	$remcmd = IniRead( $ini, "remove", "cmdline", "-" )
    $cmd = IniRead( $ini, "install", "cmdline", "-" )
	$processname = IniRead( $ini, "install", "procname", "-" )

    If $checkfile <> "-" Then

		If $cmd = "-" Then

			LogError( "Mis een benodige instelling (cmdline) in de .ini file van " & $package )
			Melding4( "Mis een benodige instelling (cmdline) in de .ini file van " & $package )
			Return
		EndIf

		LogDebug( "version: " & $package_version )
		LogDebug( "package: " & $packagezip )
		LogDebug( "checkfile: " & $checkfile )
		LogDebug( "cmdline: " & $cmd )


		$cf  = StringReplace( $checkfile, "%ProgramFiles%", @ProgramFilesDir )

		If FileExists( $cf ) Then

			LogWarning( "Pakket (" & $package & ") reeds geïnstalleerd" )
			If $loc_ver = "" Then
				SetPackageInfo( $package, $package_version, $checkfile, $remcmd, $tag_list )
			EndIf
			Return True

		EndIf

		; Downloaden pakket
		LogInfo( "Downloaden van pakket: " & $package )
		Melding4( "Downloaden pakket gestart" )
		InetGet( $url & "\" & $packagezip, @TempDir & "\" & $packagezip )
		if @error<>0 Then
			LogError( "Kan pakket niet downloaden. (" & $packagezip & ")" )
			Melding4( "Kan pakket niet downloaden. (" & $packagezip & ")" )
			Return False
		EndIf

		; test de zipfile
		LogInfo( "Pakket .zip testen" )
		Melding4( "Pakket .zip testen" )
		LogDebug( @ScriptDir & "\unzip.exe -t -qq " & @TempDir & "\" & $packagezip )
		$err = RunWait(  @ScriptDir & "\unzip.exe -t -qq " & @TempDir & "\" & $packagezip, @TempDir, @SW_HIDE  )
		If $err <> 0 Then

			LogError( "ZIP corrupt (" & $packagezip & ")" )
			Melding4( "ZIP corrupt (" & $packagezip & ")" )
			Return False

		EndIf

		; pakket uitpakken
		LogInfo( "Uitpakken van pakket: " & $package )
		Melding4( "Uitpakken pakket gestart" )
		$err = RunWait(  @ScriptDir & "\unzip.exe -o -qq -d " & @TempDir & "\" & $package & " " & @TempDir & "\"  & $packagezip , @TempDir, @SW_HIDE  )
		If $err <> 0 Then
		EndIf
		Melding4( "Uitpakken pakket gereed" )
		LogInfo( "Uitpakken (" & $package & ") gereed." )


		; pakket installeren
		$workdir = @WorkingDir
		FileChangeDir(  @TempDir & "\" & $package )

		$cmd = StringReplace( $cmd, "%ProgramFiles%", @ProgramFilesDir )
		$cmd = StringReplace( $cmd, "%MyDocuments%", @MyDocumentsDir )
		$cmd = StringReplace( $cmd, "%Windows%", @WindowsDir )

		Melding4( "Installeren pakket" )
		if StringLeft($cmd, 1) = "!" Then
			; Run as DOS command
			$cmd = @ComSpec & " /c " & StringMid($cmd, 2)
		EndIf
		LogInfo( "Installeren starten: " & $cmd )

		if $processname = "-" Then
			LogDebug( "Wachten op einde van programma" )
			RunWait( $cmd, @TempDir, @SW_HIDE  )
		Else
			$p = StringInStr($cmd, " " )

			ShellExecute( @TempDir & "\" & $package & "\" & StringLeft($cmd,$p-1), StringMid($cmd, $p+1), @TempDir & "\" & $package, "", @SW_HIDE  )
			Sleep( 500 )
			; installer kan een ander proces opstarten, hierop wachten:
			LogDebug( "Wachten op proces: " & $processname )
			ProcessWaitClose( $processname, 600 )
		EndIf


		FileChangeDir( $workdir )

		Melding4( "Installeren (" & $package & ") gereed." )

		;LogDebug( "cf: " & $cf )


		If Not FileExists( $cf ) Then

			LogError( "Pakket (" & $package & ") niet goed geïnstalleerd." )
			Melding4( "Pakket (" & $package & ") niet goed geïnstalleerd. Controle is gefaald." )
			Return False
		EndIf

		$remcmd = IniRead( $ini, "remove", "cmdline", "" )
		;LogDebug( $remcmd )


	Else
		LogInfo( "Geen install gedeelte" )
	EndIf ; [install] section exists

	;
	; TAGS
	;

	if @OSArch = "X64" Then

		$arr = IniReadSection( $ini, "tags64" )
		if @error = 1 then ; Geen tag64 sectie

			$arr = IniReadSection( $ini, "tags" )

		EndIf
	Else
		$arr = IniReadSection( $ini, "tags" )
	EndIf

	if $tag_list <> "" Then
		LogInfo( "Remove old tags" )
		$arr = StringSplit( $tag_list, "," , 2 )

		For $i = 0  to UBound($arr)
			RegDelete( "HKEY_CURRENT_USER\Software\MKSoft\Updater\Tags", $arr[$i] )
		Next
	EndIf

	if IsArray( $arr ) Then
		$tag_list = ""
		for $i = 1 to $arr[0][0]
			LogDebug( $arr[$i][0] & " = " & $arr[$i][1] )
			RegWrite("HKEY_CURRENT_USER\Software\MKSoft\Updater\Tags", $arr[$i][0], "REG_SZ",  $arr[$i][1] )
			if @error = 0 Then
				$tag_list = $tag_list & "," & $arr[$i][0]
			EndIf

		Next
		$tag_list = StringMid( $tag_list, 2 )
	EndIf

	SetPackageInfo( $package, $package_version, $checkfile, $remcmd, $tag_list )

	Return True

EndFunc

Func RemovePackage( $package )
Dim $loc_ver, $loc_remcmd, $loc_checkfile, $tag_list
Dim $package_deleted

	$package_deleted = False

	LogDebug( "verwijder " & $package )
	GetPackageInfo( $package, $loc_ver, $loc_checkfile, $loc_remcmd, $tag_list )
	LogDebug( "versie " & $loc_ver )
	if $loc_ver = "" Then Return $package_deleted

	Melding4( "Verwijder pakket: " & $package )

	$cmd  = StringReplace( $loc_remcmd, "%ProgramFiles%", @ProgramFilesDir )

	LogDebug( "cmd: " & $cmd )
	if $cmd = "" or $cmd = "-" Then
	Else
		RunWait( $cmd, @TempDir, @SW_HIDE  )
		if @error <> 0 Then
			LogError( "Error: " & @error )
			Return $package_deleted
		endif

		$cf  = StringReplace( $loc_checkfile, "%ProgramFiles%", @ProgramFilesDir )
		$cf  = StringReplace( $cf, "%MyDocuments%", @MyDocumentsDir )

		If Not FileExists( $cf ) Then
			$package_deleted = True
		Else
			LogError( "package is niet verwijderd." )
			Return False
		EndIf
	EndIf

	; REMOVE TAGS
	If $tag_list <> "" and $tag_list <> "-" Then
		$arr = StringSplit( $tag_list, "," , 0 )

		For $i = 1  to $arr[0]
			LogDebug( "Deleting tag: " & $arr[$i] )
			RegDelete( "HKEY_CURRENT_USER\Software\MKSoft\Updater\Tags", $arr[$i] )
		Next
	EndIf

	DelPackageInfo( $package )

	Return True

EndFunc

Func UpdatePackage( $package, $url )
	Return False
EndFunc

#EndRegion



#Region Test
Func _TestPackageInstaller()
	InstallPackage( "gsview", "http://localhost/Packages" )
	;RemovePackage( "gsview" )
EndFunc

;~ _TestPackageInstaller()

#EndRegion

; --------------- END OF FILE ---------------------------------------------------------------------------------------------------
