#ifndef WRITELINE_BI
#define WRITELINE_BI

#ifndef unicode
#define unicode
#endif
#include once "windows.bi"

Declare Function WriteLine( _
	ByVal hOut As Handle, _
	ByVal s As WString Ptr _
)As Integer

#endif
