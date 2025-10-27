void CrewChief_SetName()
{
    if(!PerkMenu_Texts[Deck_CrewChief][0])
    {
        FormatEx(PerkMenu_Texts[Deck_CrewChief], 64, "Crew Chief");
    }
}
/*
void CrewChief_OnMapStart()
{

}
*/

void CrewChief_PerkSelect(int client)
{
    CreateTimer(0.1, CrewChief_Timer, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    
    User_PerkStats[client].cb_perk_destroyeverything = CrewChief_DestroyEverything;
}

void CrewChief_DestroyEverything(int client)
{

}

static Action CrewChief_Timer(Handle timer, int id)
{
    int client = GetClientOfUserId(id);
    if (!IsValidMulti(client, _, _,  true, true, true) || User_PerkStats[client].Current_PerkDeck != Deck_CrewChief || g_nRoundState == SZFRoundState_End)
    {
        return Plugin_Stop;
    }
    
    return Plugin_Continue;
}