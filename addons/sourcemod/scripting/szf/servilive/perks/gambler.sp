void Gambler_SetName()
{
    if(!PerkMenu_Texts[Deck_Gambler][0])
    {
        FormatEx(PerkMenu_Texts[Deck_Gambler], 64, "Gambler");
    }
}
/*
void Gambler_OnMapStart()
{

}
*/

void Gambler_PerkSelect(int client)
{
    CreateTimer(0.1, Gambler_Timer, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    
    User_PerkStats[client].cb_perk_destroyeverything = Gambler_DestroyEverything;
}

void Gambler_DestroyEverything(int client)
{

}

static Action Gambler_Timer(Handle timer, int id)
{
    int client = GetClientOfUserId(id);
    if (!IsValidMulti(client, _, _,  true, true, true) || User_PerkStats[client].Current_PerkDeck != Deck_Gambler || g_nRoundState == SZFRoundState_End)
    {
        return Plugin_Stop;
    }
    
    return Plugin_Continue;
}