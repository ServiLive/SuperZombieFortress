Handle SyncHUD_Armor;

char Armor_HitSound[MAXPLAYERS+1][PLATFORM_MAX_PATH];
char Armor_BreakSound[MAXPLAYERS+1][PLATFORM_MAX_PATH];

enum struct Armor
{
    int client;
    float CurrentArmor;
	float MaxArmor;
	float Armor_RegenSpeed;
    float Armor_RegenDelay;
    float Armor_RegenDelayAmount;
    float Armor_ResistAmount;
    float Armor_OverDamageMult;

    // Used for armor hud updates
    float Armor_RecentlyAddedArmor;
    float Armor_RecentAddArmorSpan;
    int Armor_RecentArmorType;

	int ArmorHUDColor[4];
	
    void SetupArmor(float startingarmor = 0.0, float maximumarmor = 0.0, float resistamount = 1.0, float overdamagemult = -0.25, float delayamount = 3.0, float regenmult = 0.0, char hitsound[PLATFORM_MAX_PATH] = "", char breaksound[PLATFORM_MAX_PATH] = "")
    {
        this.MaxArmor = maximumarmor; // Lo mas importante
        
        this.CurrentArmor = startingarmor;
        this.Armor_ResistAmount = resistamount;
        this.Armor_OverDamageMult = overdamagemult;
        this.Armor_RegenDelayAmount = delayamount;
        this.Armor_RegenSpeed = regenmult;
        FormatEx(Armor_HitSound[this.client], PLATFORM_MAX_PATH, "%s", hitsound);
        FormatEx(Armor_BreakSound[this.client], PLATFORM_MAX_PATH, "%s", breaksound);

        if(this.MaxArmor > 0.0)
        {
            CreateTimer(0.1, Armor_ShowHUD, GetClientUserId(this.client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        }
    }
	bool AddArmor(float amount, int type, bool passive = false, float showspan = 1.0)
	{
		if (this.MaxArmor <= 0)
			return false;
        
        if (this.CurrentArmor > this.MaxArmor)
			return false;

        switch(type)
        {
            case 1: // Setear
            {
                this.CurrentArmor = amount;
            }
            case 2: // Multiplicar
            {
                this.CurrentArmor *= amount;
            }
            case 3: // Dividir
            {
                this.CurrentArmor /= amount;
            }
            default: // Añadir/Add
            {
                this.CurrentArmor += amount;
            }
        }

        if(!passive)
        {
            float trueamount = amount;
            if(type == 0)
            {
                if(this.CurrentArmor + trueamount > this.MaxArmor)
                {
                    trueamount = (this.MaxArmor - this.CurrentArmor);
                }
            }
            this.Armor_RecentlyAddedArmor = trueamount;
            this.Armor_RecentArmorType = type;
            this.Armor_RecentAddArmorSpan = GetGameTime() + showspan;
        }
		
        if(this.CurrentArmor > this.MaxArmor)
            this.CurrentArmor == this.MaxArmor;
		
		return true;
	}
	
	float GetCurrentArmor()
	{
		float totalarmor = -1.0;

        if(this.MaxArmor > 0.0)
        {
            totalarmor = this.CurrentArmor;
        }
		
		return totalarmor;
	}
    float GetMaxArmor()
	{
		float totalarmor = -1.0;

        if(this.MaxArmor > 0.0)
        {
            totalarmor = this.MaxArmor;
        }
		
		return totalarmor;
	}
}

Armor User_ArmorStats[MAXPLAYERS+1];

void Armor_Init()
{
    SyncHUD_Armor = CreateHudSynchronizer();
}

void Armor_ReduceDamage(int victim, float &damage, bool &changed)
{
    if(User_ArmorStats[victim].MaxArmor > 0.0)
    {
        if(User_ArmorStats[victim].CurrentArmor > 0.0)
        {
            float victimpos[3];
            GetClientAbsOrigin(victim, victimpos);

            User_ArmorStats[victim].CurrentArmor -= damage;
            if(User_ArmorStats[victim].CurrentArmor < 0.0)
            {
                    EmitSoundToAll(Armor_BreakSound[victim], victim, _, _, _, 1.0, GetRandomInt(80, 120), victim, victimpos, _, true);
                    spawnRing(victim, 10.0, 0.0, 0.0, 5.0, _, _, _, _, 255, 75, 75, 150, 15, 0.4, 8.0, 4.0, 10, 200.0);
                    spawnRing(victim, 10.0, 0.0, 0.0, 30.0, _, _, _, _, 255, 75, 75, 150, 15, 0.4, 8.0, 4.0, 10, 200.0, true);
                    User_ArmorStats[victim].CurrentArmor = 0.0;
            }
            else
            {
                    EmitSoundToAll(Armor_HitSound[victim], victim, _, _, _, 0.5, GetRandomInt(80, 120), victim, victimpos, _, true, 1.0);
            }

            if(User_ArmorStats[victim].CurrentArmor > damage)
            {
                    damage *= User_ArmorStats[victim].Armor_ResistAmount;
            }
            else
            {
                    damage *= User_ArmorStats[victim].Armor_ResistAmount + (User_ArmorStats[victim].Armor_ResistAmount * User_ArmorStats[victim].Armor_OverDamageMult);
            }
            changed = true;
        }

            User_ArmorStats[victim].Armor_RegenDelay = GetGameTime() + User_ArmorStats[victim].Armor_RegenDelayAmount;
    }
}

static Action Armor_ShowHUD(Handle timer, int id)
{
    int client = GetClientOfUserId(id);
    if(!IsValidMulti(client, true, true) || User_ArmorStats[client].MaxArmor <= 0.0 || g_nRoundState == SZFRoundState_End)
    {
        return Plugin_Stop;
    }

    int r = 255, g = 255, b = 0;
    char ArmorText[128];

    if(User_ArmorStats[client].CurrentArmor < User_ArmorStats[client].MaxArmor)
    {
        r = RoundToCeil(User_ArmorStats[client].CurrentArmor) * 255 / RoundToCeil(User_ArmorStats[client].MaxArmor);
        g = RoundToCeil(User_ArmorStats[client].CurrentArmor) * 255 / RoundToCeil(User_ArmorStats[client].MaxArmor);
                    
        r = 255 - r;
    }
    else
    {
        b = 255;
    }

    FormatEx(ArmorText, sizeof(ArmorText), "%s⛉ [%.f/%.f]\n", ArmorText, User_ArmorStats[client].CurrentArmor, User_ArmorStats[client].MaxArmor);
    if(User_ArmorStats[client].Armor_RegenDelay > GetGameTime())
    {
        FormatEx(ArmorText, sizeof(ArmorText), "%s(%.1f)", ArmorText, User_ArmorStats[client].Armor_RegenDelay - GetGameTime());
    }
    else
    {
        if(User_ArmorStats[client].CurrentArmor < User_ArmorStats[client].MaxArmor)
        {
            User_ArmorStats[client].AddArmor(User_ArmorStats[client].CurrentArmor += (User_ArmorStats[client].MaxArmor * User_ArmorStats[client].Armor_RegenSpeed), 0, true);
            FormatEx(ArmorText, sizeof(ArmorText), "%s(+++)", ArmorText);
        }
    }

    if(User_ArmorStats[client].Armor_RecentAddArmorSpan > GetGameTime())
    {
        char type[8] = "+";
        switch(User_ArmorStats[client].Armor_RecentArmorType)
        {
            case 1: Format(type, 8, "=");
            case 2: Format(type, 8, "x");
            case 3: Format(type, 8, "/");
        }
        FormatEx(ArmorText, sizeof(ArmorText), "%s %s%.1f", ArmorText, type, User_ArmorStats[client].Armor_RecentlyAddedArmor);
    }

    SetHudTextParams(-1.0, 0.84, 0.1, r, g, b, 255);
    ShowSyncHudText(client, SyncHUD_Armor, ArmorText);
    return Plugin_Continue;
}