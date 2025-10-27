void Armorer_SetName()
{
    if(!PerkMenu_Texts[Deck_Armorer][0])
    {
        FormatEx(PerkMenu_Texts[Deck_Armorer], 64, "Armorer");
    }
}
/*
void Armorer_OnMapStart()
{

}
*/

void Armorer_PerkSelect(int client)
{
    CreateTimer(0.1, Armorer_Timer, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    
    User_PerkStats[client].cb_perk_destroyeverything = Armorer_DestroyEverything;
}

void Armorer_DestroyEverything(int client)
{

}

static Action Armorer_Timer(Handle timer, int id)
{
    int client = GetClientOfUserId(id);
    if (!IsValidMulti(client, _, _,  true, true, true) || User_PerkStats[client].Current_PerkDeck != Deck_Armorer || g_nRoundState == SZFRoundState_End)
    {
        return Plugin_Stop;
    }
    
    return Plugin_Continue;
}