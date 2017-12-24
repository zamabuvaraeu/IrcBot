#include once "Irc.bi"

Type IrcBot
	Dim IrcServer As WString Ptr
	Dim Port As WString Ptr
	Dim BotNick As WString Ptr
	Dim UserString As WString Ptr
	Dim Description As WString Ptr
	Dim Client As IrcClient
	
	Dim InHandle As Handle
	Dim OutHandle As Handle
	Dim ErrorHandle As Handle
	
	Dim SavedChannel As WString * (IrcClient.MaxBytesCount + 1)
	Dim SavedUser As WString * (IrcClient.MaxBytesCount + 1)
	
	Dim AdminAuthenticated As Boolean
End Type

Declare Sub InitializeIrcBot( _
	ByVal pBot As IrcBot Ptr, _
	ByVal RealBotVersion As WString Ptr _
)
