#ifndef PROCESSEXECUTECOMMAND_BI
#define PROCESSEXECUTECOMMAND_BI

#include once "Bot.bi"

Declare Sub ProcessExecuteCommand( _
	ByVal pBot As IrcBot Ptr, _
	ByVal User As WString Ptr, _
	ByVal Channel As WString Ptr, _
	ByVal MessageText As WString Ptr _
)

#endif
