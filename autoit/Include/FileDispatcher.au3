Func FileDispatcher( $fn, $dispatch_table )
	$file = FileOpen( $fn, 0 )
	;ConsoleWrite( "! " & $fn & @CRLF )
	; Start de scan loop
	while 1

		$line = FileReadLine( $file )
		if @error <> 0 then ExitLoop

		;ConsoleWrite( "!  " & $line & @CRLF )

		$idx = 0
		while 1

			if UBound( $dispatch_table ) <= $idx Then ExitLoop

			$re = $dispatch_table[$idx][0]
			$fnc = $dispatch_table[$idx][1]

			if $re = "" then ExitLoop
			;ConsoleWrite( "+ " & $re & " -  " & $fnc & @CRLF )

			$args = StringRegExp( $line, $re, 2 )
			if @error = 0 Then
				;ConsoleWrite( "+ MATCH" & @CRLF )
				if $fnc = "*EXIT*" Then ExitLoop 2
				if $fnc <> "" Then Call( $fnc, $args )
				if @error <> 0 Then
					;ConsoleWrite( "--BREAK--" & @CRLF )
					ExitLoop 2
				EndIf
				ExitLoop
			EndIf

			$idx += 1
			;ConsoleWrite("..." & @CRLF)
		WEnd

	WEnd

	FileClose($file)
EndFunc
