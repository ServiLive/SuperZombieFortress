#define MANIAC_ARMOR_HITSOUND ""
#define MANIAC_ARMOR_BREAKSOUND ""

void Maniac_SetName()
{
    if(!PerkMenu_Texts[Deck_Maniac][0])
    {
        FormatEx(PerkMenu_Texts[Deck_Maniac], 64, "Maniac");
    }
}
/*
void Maniac_OnMapStart()
{
    PrecacheSound(MERC_ARMOR_HITSOUND, true);
    PrecacheSound(MERC_ARMOR_BREAKSOUND, true);
}
*/

void Maniac_PerkSelect(int client)
{
    User_ArmorStats[client].SetupArmor(float(SDKCall_GetMaxHealth(client)) * 0.35, float(SDKCall_GetMaxHealth(client)) * 0.35, 0.35, -0.5, 3.0, 0.1, MANIAC_ARMOR_HITSOUND, MANIAC_ARMOR_BREAKSOUND);
    
    CreateTimer(0.1, Maniac_Timer, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    
    User_PerkStats[client].cb_perk_destroyeverything = Maniac_DestroyEverything;
}

void Maniac_DestroyEverything(int client)
{
    User_ArmorStats[client].SetupArmor();
}

static Action Maniac_Timer(Handle timer, int id)
{
    int client = GetClientOfUserId(id);
    if (!IsValidMulti(client, _, _,  true, true, true) || User_PerkStats[client].Current_PerkDeck != Deck_Maniac || g_nRoundState == SZFRoundState_End)
    {
        return Plugin_Stop;
    }
    
    return Plugin_Continue;
}