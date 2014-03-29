#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.0.0
 Author:         Maurice Koster

 Script Function:
	Replaces tags in a text file and saves resulting file

#ce ----------------------------------------------------------------------------
#include-once

Func ReplaceTags( $line, $tag_arr, $path_sep = "\", $case_sensitive = False)

	$ret_line = $line
	;ConsoleWrite( " in: " & $line & @CRLF )
	for $idx = 0 to UBound( $tag_arr ) - 1
		$pat = $tag_arr[$idx][0]
		$replace = $tag_arr[$idx][1]

		$replace = StringReplace( $replace, "\", $path_sep )
		$replace = StringReplace( $replace, "\", "\\" ) ; to escape it for the regex parser
		;LogDebug( "replace: " & $replace )
		if $pat = "" Then ExitLoop

		if not $case_sensitive then $pat = "(?i)" & $pat

		;ConsoleWrite( "line: " & $ret_line & " | " &  $pat & " :: " & $replace & @CRLF )
		$ret_line = StringRegExpReplace( $ret_line, $pat, $replace )
	Next
	;ConsoleWrite( " out: " & $ret_line & @CRLF )
	Return $ret_line

EndFunc

Func FileReplaceTags( $fn_in, $fn_out, $tag_arr, $path_sep = "\\", $case_sensitive = True )
;LogDebug( "path_sep: '" & $path_sep & "'" )
	$file_in = FileOpen( $fn_in, 0 )
	if @error <> 0 Then Return

	$file_out = FileOpen( $fn_out, 2 )
	if @error <> 0 Then Return

	While 1

		$line = FileReadLine( $file_in )
		if @error <> 0 Then ExitLoop

		$line = ReplaceTags( $line, $tag_arr, $path_sep, $case_sensitive )

		FileWriteLine( $file_out, $line )
		;ConsoleWrite( $line & @CRLF )
	WEnd

	FileClose( $file_out )
	FileClose( $file_in )

EndFunc

Func ReplaceDirTags($fn)
Dim $arr[10][2] = [ _
	[ "{{windir}}",      @WindowsDir ], _
	[ "{{programfiles}}",@ProgramFilesDir ], _
	[ "{{desktop}}",	 @DesktopDir ], _
	[ "{{menu}}",	 	 @StartMenuDir & "\Programs" ], _
	[ "{{startmenudir}}",@StartMenuDir & "\Programs" ], _
	[ "#",               @AppDataDir ], _
	[ "{{userappdata}}", @AppDataDir ], _
	[ "\$",               @MyDocumentsDir ], _
	[ "{{mydocuments}}", @MyDocumentsDir ] _
]

	Return ReplaceTags( $fn, $arr, "\", False )

EndFunc

#Region Test

func _test_ReplaceTags()

Dim $arr[10][2] = [ _
	[ "{{windir}}",     @WindowsDir ], _
	[ "{{progfiles}}",  @ProgramFilesDir ], _
	[ "{{mydocuments}}", @MyDocumentsDir ] _
]

	ConsoleWrite( ReplaceTags("{{windir}}::{{progfiles}}", $arr, "/" ) & @CRLF )
	ConsoleWrite( ReplaceTags("{{windir}}::{{progfiles}}", $arr ) & @CRLF )
EndFunc


func _test_FileReplaceTags()

Dim $arr[10][2] = [ _
	[ "{{windir}}",     @WindowsDir ], _
	[ "{{progfiles}}",  @ProgramFilesDir ], _
	[ "{{mydocuments}}", @MyDocumentsDir ] _
]

	FileReplaceTags( @ScriptDir & "\test.sample", @ScriptDir & "\test.txt", $arr, "\", False )

EndFunc


;_test_FileReplaceTags()
;_test_ReplaceTags()
#EndRegion
