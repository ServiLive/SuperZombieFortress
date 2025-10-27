void Stoic_SetName()
{
    if(!PerkMenu_Texts[Deck_Stoic][0])
    {
        FormatEx(PerkMenu_Texts[Deck_Stoic], 64, "Stoic");
    }
}
/*
void Stoic_OnMapStart()
{

}
*/

void Stoic_PerkSelect(int client)
{
    CreateTimer(0.1, Stoic_Timer, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    
    User_PerkStats[client].cb_perk_destroyeverything = Stoic_DestroyEverything;
}

void Stoic_DestroyEverything(int client)
{

}

static Action Stoic_Timer(Handle timer, int id)
{
    int client = GetClientOfUserId(id);
    if (!IsValidMulti(client, _, _,  true, true, true) || User_PerkStats[client].Current_PerkDeck != Deck_Stoic || g_nRoundState == SZFRoundState_End)
    {
        return Plugin_Stop;
    }
    
    return Plugin_Continue;
}