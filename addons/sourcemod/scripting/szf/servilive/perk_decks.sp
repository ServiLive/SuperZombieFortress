Handle SyncHUD_Perks;

static bool M2Down[MAXPLAYERS+1];
static bool M3Down[MAXPLAYERS+1];
static bool RDown[MAXPLAYERS+1];

enum
{
	Deck_None, // 0
    Deck_Mercenary, // 1
	Deck_Armorer,
	Deck_CrewChief,
	Deck_Gambler,
    Deck_Maniac,
    Deck_TagTeam,
    Deck_Stoic, // 7

    Deck_MAX
};

int PerkMenu_RGBA[Deck_MAX][3];
char PerkMenu_Texts[Deck_MAX][64];

enum struct Perks
{
    int client;
    int Current_PerkDeck;
	int HeadParticle;
    int PerkSelectNumber;
    bool IsSelecting;
    Function cb_perk_spawn;
	//Function cb_perk_think;
	//Function cb_perk_touch;
	Function cb_perk_ontaken;
	Function cb_perk_ondealt;
	Function cb_perk_death;
	Function cb_perk_onkill;
    Function cb_perk_runcmd;
    Function cb_perk_destroyeverything;

    void EnablePerkDeck(int type = Deck_Mercenary)
    {
        this.DisablePerks();

        this.Current_PerkDeck = type;
        CPrintToChat(this.client, "%t", "Perk Selected");
        
        switch(type)
        {
            case Deck_Armorer:
            {
                Armorer_PerkSelect(this.client);
            }
            case Deck_CrewChief:
            {
                CrewChief_PerkSelect(this.client);
            }
            case Deck_Gambler:
            {
                Gambler_PerkSelect(this.client);
            }
            case Deck_Maniac:
            {
                Maniac_PerkSelect(this.client);
            }
            case Deck_TagTeam:
            {
                TagTeam_PerkSelect(this.client);
            }
            case Deck_Stoic:
            {
                Stoic_PerkSelect(this.client);
            }
            default:
            {
                Mercenary_PerkSelect(this.client);
            }
        }

        for(int i = 1; i < 5; i++)
        {
            char ExtraDesc[PLATFORM_MAX_PATH];
            FormatEx(ExtraDesc, sizeof(ExtraDesc), "%s Desc %d", PerkMenu_Texts[type], i);
            if(TranslationPhraseExists(ExtraDesc))
            {
                CPrintToChat(this.client, "%t", ExtraDesc);
            }
        }
    }
    void DisablePerks()
    {
        this.Current_PerkDeck = Deck_None;

        if(IsValidEntity(this.HeadParticle))
        {
            CreateTimer(0.1, Timer_RemoveEntity, EntIndexToEntRef(this.HeadParticle), TIMER_FLAG_NO_MAPCHANGE);
        }

        this.cb_perk_spawn = INVALID_FUNCTION;
        this.cb_perk_ontaken = INVALID_FUNCTION;
        this.cb_perk_ondealt = INVALID_FUNCTION;
        this.cb_perk_death = INVALID_FUNCTION;
        this.cb_perk_onkill = INVALID_FUNCTION;
        this.cb_perk_runcmd = INVALID_FUNCTION;

        if (this.cb_perk_destroyeverything != INVALID_FUNCTION)
        {
            Call_StartFunction(null, this.cb_perk_destroyeverything);
            Call_PushCell(this.client);
            Call_Finish();
        }

        this.cb_perk_destroyeverything = INVALID_FUNCTION;
    }
}

Perks User_PerkStats[MAXPLAYERS+1];

public Action Perks_OpenMenu(int client, int args)
{
	if(g_nRoundState != SZFRoundState_Grace)
	{
		return Plugin_Handled;
	}

	if(User_PerkStats[client].IsSelecting)
	{
		return Plugin_Handled;
	}
	
	if(IsValidMulti(client, false, false, true, true, true))
	{
        User_ArmorStats[client].SetupArmor();
		User_PerkStats[client].DisablePerks();
		User_PerkStats[client].IsSelecting = true;
		CreateTimer(0.1, Perk_ShowSelectionMenu, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Handled;
}

void Perk_Init()
{
    RegConsoleCmd("szf_perks", Perks_OpenMenu, "Abre el menu de Perk Decks.");

    SyncHUD_Perks = CreateHudSynchronizer();
    LoadTranslations("superzombiefortress_svl_perkdeck.phrases");
}

Action Perk_ShowSelectionMenu(Handle timer, int id)
{
    int client = GetClientOfUserId(id);
    if(!IsValidMulti(client, false, _, true, true, true) || User_PerkStats[client].Current_PerkDeck != Deck_None)
    {
        User_PerkStats[client].IsSelecting = false;
        return Plugin_Stop;
    }

    if(g_nRoundState != SZFRoundState_Grace)
    {
        if(User_PerkStats[client].Current_PerkDeck == Deck_None)
        {
            User_PerkStats[client].EnablePerkDeck(); // Darle el perk deck default, que seria mercenario
        }

        PrintToChat(client, "Menu closed due to grace period end");
        User_PerkStats[client].IsSelecting = false;
        return Plugin_Stop;
    }

    int selectnumber = User_PerkStats[client].PerkSelectNumber;
    int r = PerkMenu_RGBA[selectnumber][0], g = PerkMenu_RGBA[selectnumber][1], b = PerkMenu_RGBA[selectnumber][2];
    if(r == 0 && g == 0 && b == 0)
    {
        r = 255;
        g = 255;
        b = 255;
    }

    char PerkText[600];
    
    if(TranslationPhraseExists(PerkMenu_Texts[selectnumber]))
    {
        char PerkDesc[600];
        FormatEx(PerkDesc, sizeof(PerkDesc), "%s Desc", PerkMenu_Texts[selectnumber]);
        FormatEx(PerkText, sizeof(PerkText), "%s%t", PerkText, PerkDesc);
    }
    else
    {
        CPrintToChat(client, "{red}ALERTA: TRADUCCION %s NO EXISTE!!!!! AVISARLE A SAMU!!!!!!!", PerkMenu_Texts[selectnumber]);
        CPrintToChat(client, "%t", "Unexpected Perk Menu Close");
        return Plugin_Stop;
    }

    SetHudTextParams(-1.0, -1.0, 0.1, r, g, b, 255);
    ShowSyncHudText(client, SyncHUD_Perks, PerkText);

    FormatEx(PerkText, sizeof(PerkText), "<[M3] %t [R]>\n%t", PerkMenu_Texts[selectnumber], "Perk Selection Tip");

    SetHudTextParams(-1.0, 0.81, 0.1, r, g, b, 255);
    ShowHudText(client, -1, PerkText);

    return Plugin_Continue;
}

void PerkDecks_RunCmd(int client, int &buttons)
{
    if(IsZombie(client))
        return;

    if(User_PerkStats[client].IsSelecting)
    {
        int perknumber = User_PerkStats[client].PerkSelectNumber;

        if(g_nRoundState == SZFRoundState_Grace)
        {
            bool M2Down2 = (buttons & IN_ATTACK2) != 0;
            bool M3Down2 = (buttons & IN_ATTACK3) != 0;
            bool RDown2 = (buttons & IN_RELOAD) != 0;

            if(M2Down2 && !M2Down[client])
            {
                User_PerkStats[client].EnablePerkDeck(perknumber);
            }

            if(M3Down2 && !M3Down[client])
            {
                User_PerkStats[client].PerkSelectNumber--;
                if(User_PerkStats[client].PerkSelectNumber <= 0)
                {
                    User_PerkStats[client].PerkSelectNumber = Deck_MAX - 1;
                }
            }

            if(RDown2 && !RDown[client])
            {
                User_PerkStats[client].PerkSelectNumber++;
                if(User_PerkStats[client].PerkSelectNumber >= Deck_MAX)
                {
                    User_PerkStats[client].PerkSelectNumber = Deck_None + 1;
                }
            }

            M2Down[client] = M2Down2;
            M3Down[client] = M3Down2;
            RDown[client] = RDown2;
        }
    }
}

void PerkDeck_OnMapStart()
{
    Mercenary_OnMapStart();
}
