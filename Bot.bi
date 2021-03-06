#include once "Irc.bi"

Type IrcBot
	Dim IrcServer As WString Ptr
	Dim Port As WString Ptr
	Dim BotNick As WString Ptr
	Dim UserString As WString Ptr
	Dim Description As WString Ptr
	
	Dim InHandle As Handle
	Dim OutHandle As Handle
	Dim ErrorHandle As Handle
	
	Dim ReceivedRawMessagesCounter As UInteger
	Dim SendedRawMessagesCounter As UInteger
	
	Dim SavedChannel As WString * (IrcClient.MaxBytesCount + 1)
	Dim SavedUser As WString * (IrcClient.MaxBytesCount + 1)
	
	Dim AdminAuthenticated As Boolean
	
	Dim Client As IrcClient
	
	Declare Sub Say( _
		ByVal Channel As WString Ptr, _
		ByVal MessageText As WString Ptr _
	)
	
	Declare Sub SayWithTimeOut( _
		ByVal Channel As WString Ptr, _
		ByVal MessageText As WString Ptr _
	)
	
End Type

Declare Sub InitializeIrcBot( _
	ByVal pBot As IrcBot Ptr, _
	ByVal RealBotVersion As WString Ptr _
)
