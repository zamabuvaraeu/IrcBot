#include once "ProcessPenisCommand.bi"
#include once "CharConstants.bi"
#include once "IntegerToWString.bi"

Function GetNickHash( _
		ByVal Nick As WString Ptr _
	)As Integer
	Dim NickHash As Integer
	Dim i As Integer
	Do While Nick[i] <> 0
		NickHash += Nick[i]
		i += 1
	Loop
	Return NickHash
End Function

Sub ProcessPenisCommand( _
		ByVal pBot As IrcBot Ptr, _
		ByVal User As WString Ptr, _
		ByVal Channel As WString Ptr, _
		ByVal MessageText As WString Ptr _
	)
	Dim PenisNick As WString Ptr = Any
	Dim wSpace1 As WString Ptr = StrChr(MessageText, WhiteSpaceChar)
	If wSpace1 = 0 Then
		PenisNick = User
	Else
		PenisNick = wSpace1 + 1
	End If
	
	Dim PenisLength As Integer = 8 + GetNickHash(PenisNick) Mod 13
	
	'Пенис у %user% длиной %PenisLength% сантиметров, вот такой: 8====Э
	Dim Buffer As WString * (IrcClient.MaxBytesCount + 1) = Any
	lstrcpy(@Buffer, "Пенис у ")
	lstrcat(@Buffer, PenisNick)
	lstrcat(@Buffer, " длиной ")
	itow(PenisLength, @Buffer + lstrlen(@Buffer), 10)
	lstrcat(@Buffer, " сантиметров, вот такой: 8")
	
	Select Case PenisLength Mod 5
		Case 0
			lstrcat(@Buffer, "---")
		Case 1
			lstrcat(@Buffer, "----")
		Case 2
			lstrcat(@Buffer, ":::")
		Case 3
			lstrcat(@Buffer, "::::")
		Case 4
			lstrcat(@Buffer, "====")
	End Select
	
	lstrcat(@Buffer, "Э")
	
	pBot->Say(Channel, @Buffer)
End Sub
