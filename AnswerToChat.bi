#ifndef ANSWERTOCHAT_BI
#define ANSWERTOCHAT_BI

#include once "Bot.bi"

Declare Sub AnswerToChat( _
	ByVal pBot As IrcBot Ptr, _
	ByVal User As WString Ptr, _
	ByVal MessageText As WString Ptr _
)

Declare Sub GetQuestionList( _
	ByVal pBot As IrcBot Ptr, _
	ByVal User As WString Ptr _
)

Declare Sub GetAnswerList( _
	ByVal pBot As IrcBot Ptr, _
	ByVal User As WString Ptr, _
	ByVal QuestionIndex As Integer _
)

Declare Sub AddQuestion( _
	ByVal pBot As IrcBot Ptr, _
	ByVal User As WString Ptr, _
	ByVal Question As WString Ptr _
)

Declare Sub AddAnswer( _
	ByVal pBot As IrcBot Ptr, _
	ByVal User As WString Ptr, _
	ByVal QuestionIndex As Integer, _
	ByVal Answer As WString Ptr _
)

#endif
