#include-once
#Include <File.au3>


#include <Array.au3>

#include "Logging.au3"

Func IsExcelRunning( )

    If WinExists( "Microsoft Excel" ) Then
    
        Return True
		
	Else
		
		Return False
		
    EndIf
	
EndFunc

Func InstallXLA( $filename )
Dim $szDrive, $szPath, $fn, $shortname, $ext 
Dim $basepath
	
    _PathSplit( $filename, $szDrive, $szPath, $shortname, $ext )

	$basepath = $szDrive & $szPath
	
    If $basepath = "" Then
    
        $basepath = @AppDataDir & "\"

	EndIf
	$fn = $shortname & $ext
	
    ;OutputDebug( $basepath )


    $versions = StringSplit("10.0,11.0,12.0", ",")
	
    For $version in $versions
		
        $count = 0
        $value = RegRead( "HKEY_CURRENT_USER\Software\Microsoft\Office\" & $version & "\Excel\Options", "Pos" )
        If @error = 0 then

			$found = False

            While 1
            
                ;OutputDebug, %version% : %count%
                if $count = 0 Then
                    $value = RegRead( "HKEY_CURRENT_USER\Software\Microsoft\Office\"  & $version & "\Excel\Options", "OPEN" )
                else
					$value = RegRead( "HKEY_CURRENT_USER\Software\Microsoft\Office\"  & $version & "\Excel\Options", "OPEN" & $count)
                EndIf
				
                If @Error <> 0 Then
                    ExitLoop
				EndIf
				
                ;OutputDebug ( $value & "," & $fn )
                If StringInStr( $value, $fn ) > 0 Then
                    ; Addin reeds aanwezig
                    ;OutputDebug( $version & ": Vervangen addin")
                    $found = True
                    If $count = 0 Then
                        RegWrite( "HKEY_CURRENT_USER\Software\Microsoft\Office\" & $version & "\Excel\Options", "OPEN", "REG_SZ", '"' & $basepath & $fn & '"' )
                    else
						RegWrite( "HKEY_CURRENT_USER\Software\Microsoft\Office\" & $version & "\Excel\Options", "OPEN" & $count, "REG_SZ", '"' & $basepath & $fn & '"')
					EndIf
                    ExitLoop
					
                EndIf

                ;OutputDebug, >>> OPEN%count%: %value%
                $count += 1
				
            WEnd

            If not $found Then
            
                ;OutputDebug( $version & ": Nieuwe addin" )
                If $count = 0 Then
					RegWrite( "HKEY_CURRENT_USER\Software\Microsoft\Office\" & $version & "\Excel\Options", "OPEN", "REG_SZ", '"' & $basepath & $fn & '"' )
				else
					RegWrite( "HKEY_CURRENT_USER\Software\Microsoft\Office\" & $version & "\Excel\Options", "OPEN" & $count, "REG_SZ", '"' & $basepath & $fn & '"')
				EndIf
				
                RegWrite( "HKEY_CURRENT_USER\Software\Microsoft\Office\" & $version & "\Excel\Add-in Manager",  $basepath & $fn, "REG_SZ","")
				
            EndIf

        	
        EndIf

    Next
	


EndFunc


Func UninstallXLA( $shortname )


   
    OutputDebug( "UninstallXLA: " & $shortname )

    $versions = StringSplit( "10.0,11.0,12.0", "," )
    For $version In $versions
    
        OutputDebug( "Versie: " & $version )
        $count = 0
        $value = RegRead( "HKEY_CURRENT_USER\Software\Microsoft\Office\" & $version & "\Excel\Options", "Pos" )
        If @error = 0 Then
        
            $found = False

            While 1
                if $count = 0 Then
                    $value = RegRead( "HKEY_CURRENT_USER\Software\Microsoft\Office\" & $version & "\Excel\Options", "OPEN" )
                Else
                    $value = RegRead( "HKEY_CURRENT_USER\Software\Microsoft\Office\" & $version & "\Excel\Options", "OPEN" & $count )
				EndIf

                If @error = 0 Then

                    If StringInStr( $value, $shortname ) Then
                    
                        OutputDebug( "Verwijder " & $version & ": (" & $count & ")" )
                        if $count = 0 Then
                            RegDelete( "HKEY_CURRENT_USER\Software\Microsoft\Office\" & $version & "\Excel\Options", "OPEN" )
                        Else
                            RegDelete( "HKEY_CURRENT_USER\Software\Microsoft\Office\" & $version & "\Excel\Options", "OPEN" & $count )
                        EndIf
                        ExitLoop
						
                    EndIf
                
                else
                    ExitLoop
					
				EndIf
				
                $count += 1
				OutputDebug( "count: " & $count )
            WEnd

			$count = 1
			OutputDebug( "addin manager" )
			$applkey = "HKEY_CURRENT_USER\Software\Microsoft\Office\" & $version & "\Excel\Add-in Manager"
			while 1
            
				$value = RegEnumVal( $applkey, $count )
				if @error <> 0 Then	
					ExitLoop
				EndIf
    	      
			    if StringInstr( $value , $shortname ) > 0 Then
	          
					;OutputDebug( "Verwijderen " & $version & " : " & $value )
					RegDelete(   $applkey, $value )
					
				EndIf
				$count += 1
	        WEnd


        EndIf
		
    Next
	OutputDebug( "Done" )
EndFunc

Func SetExcelVBAsecurity($security=1)

    ;OutputDebug( "SetExcelVBAsecurity" )
    $dummy = RegRead( "HKEY_CURRENT_USER\Software\Microsoft\Office\12.0\Excel\Security", "AccessVBOM" )
    If @error = 0 Then
    
        ;OutputDebug( "Set 12.0 security" )
        RegWrite( "HKEY_CURRENT_USER\Software\Microsoft\Office\12.0\Excel\Security", "AccessVBOM",  "REG_DWORD", $security )
		
    EndIf

    $dummy = RegRead( "HKEY_CURRENT_USER\Software\Microsoft\Office\11.0\Excel\Security", "AccessVBOM" )
    If @Error = 0 Then
    
        ;OutputDebug( "Set 11.0 security" )
        RegWrite( "HKEY_CURRENT_USER\Software\Microsoft\Office\11.0\Excel\Security", "AccessVBOM",  "REG_DWORD", $security )
		
    EndIf
	
EndFunc

Func ExcelAddinsFolder()
	
	$versions = StringSplit( "12.0,11.0,10.0", "," )
	For $version IN $versions
		$p = RegRead( "HKEY_CURRENT_USER\Software\Microsoft\Office\" & $version & "\Common\General", "AddIns" )
		if @error = 0 Then
			Return @AppDataDir & "\Microsoft\" & $p
		EndIf
	Next
	
	; Nothing found, best guess:
	Return @AppDataDir & "\Microsoft\Addins"
	
EndFunc

Func ExcelAddinList()
Dim $list
	
	OutputDebug( "ExcelAddinList" )

    $versions = StringSplit( "10.0,11.0,12.0", "," )
    For $version In $versions
    
        ;OutputDebug( "Versie: " & $version )
        $count = 0
        $value = RegRead( "HKEY_CURRENT_USER\Software\Microsoft\Office\" & $version & "\Excel\Options", "Pos" )
        If @error = 0 Then
        
            $found = False

            While 1
                if $count = 0 Then
                    $value = RegRead( "HKEY_CURRENT_USER\Software\Microsoft\Office\" & $version & "\Excel\Options", "OPEN" )
                Else
                    $value = RegRead( "HKEY_CURRENT_USER\Software\Microsoft\Office\" & $version & "\Excel\Options", "OPEN" & $count )
				EndIf

                If @error = 0 Then
					if StringInStr( $value, ".xla" ) > 0 And StringInStr( $value, @ProgramFilesDir & "\Microsoft Office\" ) = 0 Then
						;ConsoleWrite($value & @CRLF )
						$arr = StringRegExp( $value, "(?U)\\([^\.\\]*).xla", 2 )
						if @error = 0 Then
							if StringInStr ( "," & $list & ",", "," & $arr[1] & "," ) = 0 then
								$list = $list & "," & $arr[1]
							EndIf
						Else
							if StringInStr ( "," & $list & ",", "," & $value & "," ) = 0 then
								$list = $list & "," & $value
							EndIf
						endif	
					EndIf
                
                else
                    ExitLoop
					
				EndIf
				
                $count += 1
				;OutputDebug( "count: " & $count )
            WEnd

			$count = 1
			;OutputDebug( "addin manager" )
			$applkey = "HKEY_CURRENT_USER\Software\Microsoft\Office\" & $version & "\Excel\Add-in Manager"
			while 1
            
				$value = RegEnumVal( $applkey, $count )
				if @error <> 0 Then	
					ExitLoop
				EndIf
    	      
			    if StringInStr( $value, ".xla" ) > 0 And StringInStr( $value, @ProgramFilesDir & "\Microsoft Office\" ) = 0 Then
					$arr = StringRegExp( $value, "(?U)\\([^\.\\]*).xla", 2 )
					if StringInStr ( ","& $list & ",", "," & $arr[1] & "," ) = 0 then
						$list = $list & "," & $arr[1]
					endif
				EndIf
				$count += 1
	        WEnd


        EndIf
		
    Next
	
	;OutputDebug( "Done" )
	$arr = StringSplit( StringMid($list,2), ",", 2 )
	_ArraySort($arr)
	Return _ArrayToString( $arr, "," )
	
EndFunc

;ConsoleWrite( ExcelAddinList() & @CRLF )