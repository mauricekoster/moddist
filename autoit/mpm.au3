#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=mk.ico
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

;
; Maurice Package Manager
;
#include <Array.au3>
#include <String.au3>

#include "Include\Logging.au3"
#include "Include\Repository.au3"
#include "Include\ModuleManagement.au3"

$base_url = GetDefaultRepositoryUrl()

if $CmdLine[0]==0 Then
	help()

ElseIf $CmdLine[1] = 'help' Then
	help()

ElseIf $CmdLine[1] = "repo" Then
	LogInfo( "repo:" )
	$Ret = GetRepositoryList()
	$def_repo = GetDefaultRepositoryNr()

	Switch $CmdLine[2]
		case "list"
			println("Repository name(s):")
			println( StringFormat(" Nr  %-15s %-55s%-3s",  "Name", "URL", "Def")  )
			println(_StringRepeat("=", 79) )
			for $i = 1 to $Ret[0]
				if $i = $def_repo then
					$extra = "(*)"
				Else
					$extra=""
				EndIf

				$L = StringSplit($Ret[$i], "|", 1)
				println( StringFormat("[%2d] %-15s %-55s%-3s", $i, $L[1], $L[2], $extra)  )
			Next
			println(_StringRepeat("=", 79) & @CRLF)

		case Else
			LogError("Unknown subcommand")

	EndSwitch
ElseIf $CmdLine[1] = "module" Then
	LogInfo( "module:" )
	$Ret = GetModuleList($base_url)


	Switch $CmdLine[2]
		case "list"
			println("List")
			println(_StringRepeat("=", 60) )

			for $i = 1 to $Ret[0]

				$L = StringSplit($Ret[$i], "|", 1)
				println( StringFormat(" %-20s", $L[1]) & "- " & $L[2] )
			Next
			println(_StringRepeat("=", 60) & @CRLF)

		case Else
			LogError("Unknown subcommand")

	EndSwitch

Else
	LogError( "Unknown command: " & $CmdLine[1] )
	help()
EndIf


Func help()
	ConsoleWrite( "Help!" & @CRLF )
EndFunc


Func println($msg)
	ConsoleWrite( $msg & @CRLF )
EndFunc