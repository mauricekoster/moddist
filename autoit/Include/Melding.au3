#include-once

Global $msg_1 = ""
Global $msg_2 = ""
Global $msg_3 = ""
Global $msg_4 = ""

Func __melding()
	$s = $msg_1 & @LF & $msg_2 & @LF & $msg_3 & @LF & $msg_4
	SplashTextOn("", $s , 700, 30+(20*4), -1, -1, 1, "", 14)
EndFunc

Func Melding($str)
	$s = StringReplace( $str, @LF, "||" )
	$s = StringReplace( $s, @CR, "" )

	$msg = StringSplit( $s, "||", 1 )
	$aantal_regels = $msg[0]

	if $aantal_regels>=1 then $msg_1 = $msg[1]
	if $aantal_regels>=2 then $msg_2 = $msg[2]
	if $aantal_regels>=3 then $msg_3 = $msg[3]
	if $aantal_regels>=4 then $msg_4 = $msg[4]

	__melding()
EndFunc

Func MeldingSluiten()
	$msg_1 = ""
	$msg_2 = ""
	$msg_3 = ""
	$msg_4 = ""

	SplashOff()
EndFunc

Func Melding1($str)
	$msg_1 = $str

	__melding()
EndFunc

Func Melding2($str)
	$msg_2 = $str

	__melding()
EndFunc

Func Melding3($str)
	$msg_3 = $str

	__melding()
EndFunc

Func Melding4($str)
	$msg_4 = $str

	__melding()
EndFunc

#cs
Melding( "Alle eendjes ||zwemmen ||in ||het water" )
Sleep(1000)
Melding1( "Bla" )
Sleep(1000)
Melding2( "Bla bla" )
Sleep(1000)
Melding3( "Bla bla bla" )
Sleep(1000)
Melding4( "Bla bla bla bla" )
Sleep(1000)
Melding( "Alle eendjes zwemmen ||in het water" )
Sleep(1000)
MeldingSluiten()
#ce
