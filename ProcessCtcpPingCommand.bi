#ifndef PROCESSCTCPINGCOMMAND_BI
#define PROCESSCTCPINGCOMMAND_BI

#include once "Bot.bi"

Declare Sub ProcessCtcpPingCommang( _
	ByVal pBot As IrcBot Ptr, _
	ByVal User As WString Ptr, _
	ByVal Channel As WString Ptr _
)

#endif
