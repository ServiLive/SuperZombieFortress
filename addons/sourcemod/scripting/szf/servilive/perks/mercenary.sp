static bool Mercenary_IsBuffed[MAXPLAYERS+1];
static float Mercenary_RegenDelay[MAXPLAYERS+1];

#define MERC_ARMOR_HITSOUND "weapons/rescue_ranger_charge_01.wav"
#define MERC_ARMOR_BREAKSOUND "npc/assassin/ball_zap1.wav"

void Mercenary_SetName()
{
    if(!PerkMenu_Texts[Deck_Mercenary][0])
    {
        FormatEx(PerkMenu_Texts[Deck_Mercenary], 64, "Mercenary");
    }
}

void Mercenary_OnMapStart()
{
    PrecacheSound(MERC_ARMOR_HITSOUND, true);
    PrecacheSound(MERC_ARMOR_BREAKSOUND, true);
}

void Mercenary_PerkSelect(int client)
{
    User_ArmorStats[client].SetupArmor(float(SDKCall_GetMaxHealth(client)) * 0.5, float(SDKCall_GetMaxHealth(client)) * 0.5, 0.6, -0.5, 3.0, 0.1, MERC_ARMOR_HITSOUND, MERC_ARMOR_BREAKSOUND);
    
    CreateTimer(0.1, Mercenary_Timer, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    
    User_PerkStats[client].cb_perk_destroyeverything = Mercenary_DestroyEverything;
}

void Mercenary_DestroyEverything(int client)
{
    User_ArmorStats[client].SetupArmor();
    Mercenary_IsBuffed[client] = false;
    Mercenary_RegenDelay[client] = 0.0;
}

static Action Mercenary_Timer(Handle timer, int id)
{
    int client = GetClientOfUserId(id);
    if (!IsValidMulti(client, _, _,  true, true, true) || User_PerkStats[client].Current_PerkDeck != Deck_Mercenary || g_nRoundState == SZFRoundState_End)
    {
        return Plugin_Stop;
    }

    int allies = 0;
	float clientPos[3];
	GetClientAbsOrigin(client, clientPos);
	float distanceneeded = 400.0;
	for (int target = 1; target <= MaxClients; target++)
	{
		if (IsValidMulti(target, _, _, true, true, true))
		{
			float targetPos[3];
			GetClientAbsOrigin(target, targetPos);
			float Distance = GetVectorDistance(targetPos, clientPos);
				
			if (Distance <= distanceneeded)
			{
				if (target != client)
				{
					allies++;
				}
			}
		}
	}
    if(allies >= 3)
        Mercenary_IsBuffed[client] = true;

    if(Mercenary_RegenDelay[client] < GetGameTime())
    {
        SelfHealClient(client, float(SDKCall_GetMaxHealth(client)) * 0.02, 1.0, true);
        Mercenary_RegenDelay[client] = GetGameTime() + 1.0;
    }
    
    return Plugin_Continue;
}