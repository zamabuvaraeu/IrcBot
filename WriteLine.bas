#include once "WriteLine.bi"
#include once "CharConstants.bi"

Const MaxConsoleCharsCount As Integer = 32000

Function WriteLine( _
		ByVal hOut As Handle, _
		ByVal s As WString Ptr _
	)As Integer
	Dim StringWithNewLine As WString * (MaxConsoleCharsCount + 1) = Any
	
	Dim dwStringWithNewLineLength As DWORD = Cast(DWORD, lstrlen(lstrcat(lstrcpy(@StringWithNewLine, s), vbCrLf)))
	
	Dim CharsCount As DWORD = Any
	
	If WriteConsole(hOut, @StringWithNewLine, dwStringWithNewLineLength, @CharsCount, 0) = 0 Then
		Dim Buffer As ZString * (MaxConsoleCharsCount) = Any
		
		Dim BytesCount As Integer = WideCharToMultiByte(GetConsoleOutputCP(), 0, @StringWithNewLine, -1, @Buffer, MaxConsoleCharsCount - 1, 0, NULL)
		
		WriteFile(hOut, @Buffer, BytesCount - 1, @CharsCount, 0)
	End If
	
	Return CharsCount
	
End Function
