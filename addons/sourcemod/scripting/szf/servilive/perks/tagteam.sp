void TagTeam_SetName()
{
    if(!PerkMenu_Texts[Deck_TagTeam][0])
    {
        FormatEx(PerkMenu_Texts[Deck_TagTeam], 64, "Tag Team");
    }
}
/*
void TagTeam_OnMapStart()
{

}
*/

void TagTeam_PerkSelect(int client)
{
    CreateTimer(0.1, TagTeam_Timer, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    
    User_PerkStats[client].cb_perk_destroyeverything = TagTeam_DestroyEverything;
}

void TagTeam_DestroyEverything(int client)
{

}

static Action TagTeam_Timer(Handle timer, int id)
{
    int client = GetClientOfUserId(id);
    if (!IsValidMulti(client, _, _,  true, true, true) || User_PerkStats[client].Current_PerkDeck != Deck_TagTeam || g_nRoundState == SZFRoundState_End)
    {
        return Plugin_Stop;
    }
    
    return Plugin_Continue;
}