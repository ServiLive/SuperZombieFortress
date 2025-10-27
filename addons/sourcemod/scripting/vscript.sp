#tryinclude <vscript>

#pragma semicolon 1
#pragma newdecls required

#define VSCRIPT_LIBRARY	"vscript"

#if defined _vscript_included
static Handle SDKGetAttribute;
static Handle SDKGetCustomAttribute;
static bool Loaded;
#endif

void VScript_OnPluginStart()
{
	#if defined _vscript_included
	Loaded = LibraryExists(VSCRIPT_LIBRARY);
    if(Loaded && VScript_IsScriptVMInitialized())
		VScript_OnScriptVMInitialized();
	#endif
}

#if defined _vscript_included
public void VScript_OnScriptVMInitialized()
{
	VScriptFunction func = VScript_GetClassFunction("CEconEntity", "GetAttribute");
	if(func)
	{
		SDKGetAttribute = func.CreateSDKCall();
		if(!SDKGetAttribute)
			LAPUTAMADREEEEEE("CEconEntity::GetAttribute");
	}
	else
	{
		LAPUTAMADREEEEEE("CEconEntity::GetAttribute");
	}

	func = VScript_GetClassFunction("CTFPlayer", "GetCustomAttribute");
	if(func)
	{
		SDKGetCustomAttribute = func.CreateSDKCall();
		if(!SDKGetCustomAttribute)
            LAPUTAMADREEEEEE("CTFPlayer::GetCustomAttribute");
	}
	else
	{
		LAPUTAMADREEEEEE("CTFPlayer::GetCustomAttribute");
	}
}
#endif

public void VScript_OnLibraryAdded(const char[] name)
{
	#if defined _vscript_included
	if(!Loaded && StrEqual(name, VSCRIPT_LIBRARY))
	{
		Loaded = true;
		
		if(VScript_IsScriptVMInitialized())
			VScript_OnScriptVMInitialized();
	}
	#endif
}

public void VScript_OnLibraryRemoved(const char[] name)
{
	#if defined _vscript_included
	if(Loaded && StrEqual(name, VSCRIPT_LIBRARY))
		Loaded = false;
	#endif
}

public bool VScript_ObtainAttribute(int entity, const char[] name, float &value)
{
	if(SDKGetAttribute && SDKGetCustomAttribute)
	{
		value = SDKCall(entity > MaxClients ? SDKGetAttribute : SDKGetCustomAttribute, entity, name, value);
		return true;
	}

	return false;
}

stock bool VScript_Loaded()
{
	#if defined _vscript_included
	return Loaded;
	#else
	return false;
	#endif
}

stock void VScript_PrintStatus()
{
	#if defined _vscript_included
	PrintToServer("'%s' is %sloaded", VSCRIPT_LIBRARY, Loaded ? "" : "not ");
	#else
	PrintToServer("'%s' not compiled", VSCRIPT_LIBRARY);
	#endif
}