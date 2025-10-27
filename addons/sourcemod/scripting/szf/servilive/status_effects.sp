static ArrayList AL_StatusEffects;

#define BUFF_ATTACKSPEED_BUFF_DISABLE (1 << 1)
#define BUFF_PROJECTILE_SPEED (1 << 2)
#define BUFF_PROJECTILE_RANGE (1 << 3)

enum struct StatusEffect
{
	char BuffName[64];			 //Used to identify
	//Desc is just, the name + desc
	/*
	Example:
	Teslar Electric
	Desc will be:
	Texlar Electric Desc
	*/

	char AboveEnemyDisplay[8]; //Should it display above their head, like silence X
	float DamageTakenMulti; //Resistance or vuln
	float DamageDealMulti;	//damage buff or nerf
	float MovementspeedModif;	//damage buff or nerf
	bool Positive;//Is it a good buff, if yes, do true
	bool ElementalLogic;

	int LinkedStatusEffect; //Which status effect is used for below
	float AttackspeedBuff;	//damage buff or nerf
	int FlagAttackspeedLogic;	//Extra Things

	//IS it elemental? If yes, dont get blocked or removed.
	int Slot; 
	int SlotPriority; 
	//If its a buff like the medigun buff where it only affects 1 more person, then it shouldnt do anything.

	//Incase more complex stuff is needed.
	//See Enfeeble
	Function OnTakeDamage_TakenFunc;
	Function OnTakeDamage_DealFunc;
	Function Status_SpeedFunc;
	Function TimerRepeatCall_Func; //for things such as regen. calls at a fixed 0.4.
	Function OnTakeDamage_PostVictim;
	Function OnTakeDamage_PostAttacker;
	Function OnBuffStarted;
	Function OnBuffEndOrDeleted;

	void Blank()
	{
		this.OnTakeDamage_PostVictim	= INVALID_FUNCTION;
		this.OnTakeDamage_PostAttacker	= INVALID_FUNCTION;
		this.OnBuffStarted				= INVALID_FUNCTION;
		this.OnBuffEndOrDeleted			= INVALID_FUNCTION;
		this.DamageTakenMulti 			= -1.0;
		this.DamageDealMulti 			= -1.0;
		this.MovementspeedModif 		= -1.0;
		this.AttackspeedBuff			= -1.0;
		this.ElementalLogic 			= false;
	}
}

static ArrayList E_AL_StatusEffects[MAXENTITIES];

enum struct E_StatusEffect
{
	bool TotalOwners[MAXENTITIES];
	/*
		Example: Teslar stick gives 25% more damage
		on a full server it would nerf that bonus to 8%
		however the user would outright get less from it and their DPS drops
		This would solve the issue where, if the owner actually applied it, they'd get the max benifit (or only more)
	*/
	float TimeUntillOver;
	int BuffIndex;

	//This is used for function things
	float DataForUse;
	int WearableUse;
	int VictimSave;
	bool MarkedForDeletion;

	void ApplyStatusEffect_Internal(int owner, int victim, bool HadBuff, int ArrayPosition)
	{
		if(!E_AL_StatusEffects[victim])
			E_AL_StatusEffects[victim] = new ArrayList(sizeof(E_StatusEffect));
		
		this.VictimSave = victim;

		if(owner > 0)
			this.TotalOwners[owner] = true;

		if(!HadBuff)
			E_AL_StatusEffects[victim].PushArray(this);
		else
			E_AL_StatusEffects[victim].SetArray(ArrayPosition, this);
	}

	void RemoveStatus(bool OnlyCastLogic = false)
	{
		static StatusEffect Apply_MasterStatusEffect;
		AL_StatusEffects.GetArray(this.BuffIndex, Apply_MasterStatusEffect);
	//	PrintToChatAll("RemoveStatus %s", Apply_MasterStatusEffect.BuffName);
		if(Apply_MasterStatusEffect.OnBuffEndOrDeleted != INVALID_FUNCTION && Apply_MasterStatusEffect.OnBuffEndOrDeleted)
		{
			Call_StartFunction(null, Apply_MasterStatusEffect.OnBuffEndOrDeleted);
			Call_PushCell(this.VictimSave);
			Call_PushArray(Apply_MasterStatusEffect, sizeof(Apply_MasterStatusEffect));
			Call_PushArray(this, sizeof(this));
			Call_Finish();
		}
		if(!OnlyCastLogic)
		{
			int ArrayPosition = E_AL_StatusEffects[this.VictimSave].FindValue(this.BuffIndex, E_StatusEffect::BuffIndex);
			E_AL_StatusEffects[this.VictimSave].Erase(ArrayPosition);
		}
	}
}

void DeleteStatusEffectsFromAll()
{
	for(int c = 0; c < MAXENTITIES; c++)
	{
		StatusEffectReset(c, true);
	}
}

int StatusEffect_AddBlank()
{
	StatusEffect data;
	data.Blank();
	return AL_StatusEffects.PushArray(data);
}

int StatusEffect_AddGlobal(StatusEffect data)
{
	if(data.AttackspeedBuff > 0.0)
	{
		/*
		//check for linked.
		if(!data.LinkedStatusEffect)
		{
			LogError("%s | NO LINKED BUFF FOR ATTACKSPEED.", data.BuffName);
		}
		*/
		data.LinkedStatusEffect 		= StatusEffect_AddBlank();
	}
	else
	{
		data.LinkedStatusEffect 		= 0;
	}
	return AL_StatusEffects.PushArray(data);
}

stock void RemoveSpecificBuff(int victim, const char[] name, int IndexID = -1, bool UpdateAttackspeed = true)
{
	int index;
	if(IndexID != -1)
		index = IndexID;
	else
		index = AL_StatusEffects.FindString(name, StatusEffect::BuffName);

	if(index == -1)
	{
		LogError("ApplyStatusEffect , invalid buff name: ''%s''",name);
		return;
	}
	E_StatusEffect Apply_StatusEffect;
	StatusEffect Apply_MasterStatusEffect;

	int ArrayPosition;
	if(E_AL_StatusEffects[victim])
	{
		ArrayPosition = E_AL_StatusEffects[victim].FindValue(index, E_StatusEffect::BuffIndex);
		if(ArrayPosition != -1)
		{
			E_AL_StatusEffects[victim].GetArray(ArrayPosition, Apply_StatusEffect);
			AL_StatusEffects.GetArray(Apply_StatusEffect.BuffIndex, Apply_MasterStatusEffect);
			if(UpdateAttackspeed)
				StatusEffect_UpdateAttackspeedAsap(victim, Apply_MasterStatusEffect, Apply_StatusEffect, false);
			Apply_StatusEffect.RemoveStatus();
		}
		
		if(E_AL_StatusEffects[victim].Length < 1)
			delete E_AL_StatusEffects[victim];
	}
}

//Got lazy, tired of doing so many indexs.

int HasSpecificBuff(int victim, const char[] name, int IndexID = -1, int attacker = 0)
{
	//doesnt even have abuff...
	if(!E_AL_StatusEffects[victim])
		return 0;

	int index;
	if(IndexID != -1)
		index = IndexID;
	else
		index = AL_StatusEffects.FindString(name, StatusEffect::BuffName);

	if(index == -1)
	{
		CPrintToChatAll("{crimson} A DEV FUCKED UP!!!!!!!!! Name %s GET AN ADMIN RIGHT NOWWWWWWWWWWWWWW!^!!!!!!!!!!!!!!!!!!one111 (more then 0)",name);
		LogError("ApplyStatusEffect A DEV FUCKED UP!!!!!!!!! Name %s",name);
		return 0;
	}
	E_StatusEffect Apply_StatusEffect;
	int ArrayPosition;
	int Return = false;
	ArrayPosition = E_AL_StatusEffects[victim].FindValue(index, E_StatusEffect::BuffIndex);
	if(ArrayPosition != -1)
	{
		E_AL_StatusEffects[victim].GetArray(ArrayPosition, Apply_StatusEffect);
		if(Apply_StatusEffect.TimeUntillOver >= GetGameTime())
		{
			if(Apply_StatusEffect.TotalOwners[attacker])
				Return = 3;
			else if(Apply_StatusEffect.TotalOwners[victim])
				Return = 2;
			else
				Return = 1;
		}
	}
	if(E_AL_StatusEffects[victim].Length < 1)
		delete E_AL_StatusEffects[victim];

	return Return;
}
stock void RemoveAllBuffs(int victim, bool RemoveGood, bool Everything = false)
{
	if(!E_AL_StatusEffects[victim])
		return;
		
	if(Everything)
	{
		delete E_AL_StatusEffects[victim];
		return;
	}
	static StatusEffect Apply_MasterStatusEffect;
	static E_StatusEffect Apply_StatusEffect;
	//No debuffs or status effects, skip.
	for(int i; i<E_AL_StatusEffects[victim].Length; i++)
	{
		E_AL_StatusEffects[victim].GetArray(i, Apply_StatusEffect);
		AL_StatusEffects.GetArray(Apply_StatusEffect.BuffIndex, Apply_MasterStatusEffect);
		if(Apply_StatusEffect.TimeUntillOver < GetGameTime() || Apply_StatusEffect.MarkedForDeletion)
		{
			StatusEffect_UpdateAttackspeedAsap(victim, Apply_MasterStatusEffect, Apply_StatusEffect, false);
			Apply_StatusEffect.RemoveStatus();
			i = 0;
			//reloop
			continue;
		}
		//They do not have a buffname, this means that it can break other things depending on this!
		if(!Apply_MasterStatusEffect.BuffName[0])
		{
			continue;
		}
		if(!Apply_MasterStatusEffect.Positive && !RemoveGood && !Apply_MasterStatusEffect.ElementalLogic)
		{
			StatusEffect_UpdateAttackspeedAsap(victim, Apply_MasterStatusEffect, Apply_StatusEffect, false);
			Apply_StatusEffect.RemoveStatus();
			i = 0;
			//reloop
			continue;
		}
		else if(Apply_MasterStatusEffect.Positive && RemoveGood && !Apply_MasterStatusEffect.ElementalLogic)
		{
			StatusEffect_UpdateAttackspeedAsap(victim, Apply_MasterStatusEffect, Apply_StatusEffect, false);
			Apply_StatusEffect.RemoveStatus();
			i = 0;
			//reloop
			continue;
		}
	}
	if(E_AL_StatusEffects[victim].Length < 1)
		delete E_AL_StatusEffects[victim];
}
stock void ApplyStatusEffect(int owner, int victim, const char[] name, float Duration, int IndexID = -1)
{
	int index;
	if(IndexID != -1)
		index = IndexID;
	else
		index = AL_StatusEffects.FindString(name, StatusEffect::BuffName);

	if(index == -1)
	{
		CPrintToChatAll("{crimson} A DEV FUCKED UP!!!!!!!!! Name %s GET AN ADMIN RIGHT NOWWWWWWWWWWWWWW!^!!!!!!!!!!!!!!!!!!one111 (more then 0)",name);
		LogError("ApplyStatusEffect A DEV FUCKED UP!!!!!!!!! Name %s",name);
		return;
	}
	StatusEffect Apply_MasterStatusEffect;
	E_StatusEffect Apply_StatusEffect;
	AL_StatusEffects.GetArray(index, Apply_MasterStatusEffect);
	if(HasSpecificBuff(victim, "Hardened Aura"))
	{
		if(!Apply_MasterStatusEffect.Positive && !Apply_MasterStatusEffect.ElementalLogic)
		{
			//Immunity to all debuffs except elementals, dont ignore buffs with no name, this is due to them having internal logic.
			if(Apply_MasterStatusEffect.BuffName[0])
				return;
		}
	}

	int CurrentSlotSaved = Apply_MasterStatusEffect.Slot;
	int CurrentPriority = Apply_MasterStatusEffect.SlotPriority;
	if(CurrentSlotSaved > 0)
	{
		//This debuff has slot logic, this means we should see which debuff is prioritised
		if(E_AL_StatusEffects[victim])
		{
			//We need to see if they have a currently prioritised buff/debuff already
			//loop through the existing debuffs?
			int length = E_AL_StatusEffects[victim].Length;
			for(int i; i<length; i++)
			{
				E_AL_StatusEffects[victim].GetArray(i, Apply_StatusEffect);
				AL_StatusEffects.GetArray(Apply_StatusEffect.BuffIndex, Apply_MasterStatusEffect);
				if(Apply_StatusEffect.TimeUntillOver < GetGameTime())
				{
					continue;
				}
				if(CurrentSlotSaved == Apply_MasterStatusEffect.Slot)
				{
					if(CurrentPriority > Apply_MasterStatusEffect.SlotPriority)
					{
						// New buff is high priority, remove this one, stop the loop
						StatusEffect_UpdateAttackspeedAsap(victim, Apply_MasterStatusEffect, Apply_StatusEffect, false);
						Apply_StatusEffect.RemoveStatus();
						i = 0;
						//reloop
						length = E_AL_StatusEffects[victim].Length;
						break;
					}
					else if(CurrentPriority < Apply_MasterStatusEffect.SlotPriority)
					{
						// New buff is low priority, Extend the stronger one if this one is longer
						index = Apply_StatusEffect.BuffIndex;
						break;
					}
				}
			}
		}
		//if this was false, then they had none, ignore.
	}


	bool HadBuffBefore = false;
	int ArrayPosition;
	if(E_AL_StatusEffects[victim])
	{
		ArrayPosition = E_AL_StatusEffects[victim].FindValue(index, E_StatusEffect::BuffIndex);
		if(ArrayPosition != -1)
		{
			HadBuffBefore = true;
			E_AL_StatusEffects[victim].GetArray(ArrayPosition, Apply_StatusEffect);
			float CurrentTime = Apply_StatusEffect.TimeUntillOver - GetGameTime();
			if(Duration > CurrentTime)
			{
				//longer duration was found, override.
				Apply_StatusEffect.TimeUntillOver = GetGameTime() + Duration;
			}
		}
	}
	Apply_StatusEffect.BuffIndex = index;
	if(!HadBuffBefore)
	{
		Apply_StatusEffect.TimeUntillOver = GetGameTime() + Duration;
	}
	Apply_StatusEffect.ApplyStatusEffect_Internal(owner, victim, HadBuffBefore, ArrayPosition);
	if(!HadBuffBefore)
	{
		AL_StatusEffects.GetArray(index, Apply_MasterStatusEffect);
		if(Apply_MasterStatusEffect.OnBuffStarted != INVALID_FUNCTION && Apply_MasterStatusEffect.OnBuffStarted)
		{
			Call_StartFunction(null, Apply_MasterStatusEffect.OnBuffStarted);
			Call_PushCell(victim);
			Call_PushArray(Apply_MasterStatusEffect, sizeof(Apply_MasterStatusEffect));
			Call_PushArray(Apply_StatusEffect, sizeof(Apply_StatusEffect));
			Call_Finish();
		}
	}
	
	int linked = Apply_MasterStatusEffect.LinkedStatusEffect;
	if(linked > 0)
	{
		ApplyStatusEffect(owner, victim, "", 9999999.9, linked);
	}
	
}

void StatusEffect_UpdateAttackspeedAsap(int victim, StatusEffect Apply_MasterStatusEffect, E_StatusEffect Apply_StatusEffect, bool HasBuff = true)
{
	if(Apply_MasterStatusEffect.AttackspeedBuff > 0.0)
	{
		//Instatly remove the sub,par buffs they had
		//do twice just in case.
		Status_Effects_AttackspeedBuffChange(victim, Apply_MasterStatusEffect, Apply_StatusEffect, HasBuff);
		RemoveSpecificBuff(victim, "", Apply_MasterStatusEffect.LinkedStatusEffect, false);
		
		Status_Effects_AttackspeedBuffChange(victim, Apply_MasterStatusEffect, Apply_StatusEffect, HasBuff);
		RemoveSpecificBuff(victim, "", Apply_MasterStatusEffect.LinkedStatusEffect, false);
	}
}

void StatusEffectReset(int victim, bool force)
{
	if(!E_AL_StatusEffects[victim])
		return;
	
	static E_StatusEffect Apply_StatusEffect;
	int length = E_AL_StatusEffects[victim].Length;
	for(int i; i<length; i++)
	{
		E_AL_StatusEffects[victim].GetArray(i, Apply_StatusEffect);
		Apply_StatusEffect.RemoveStatus(true);
		//only remove effects.
	}

	if(force)
	{
		delete E_AL_StatusEffects[victim];
		return;
	}

}

/*
bool StatusEffects_HasDebuffOrBuff(int victim)
{
	if(!E_AL_StatusEffects[victim])
		return false;
	
	return true;
}
*/
//any buff that gives you resistances
/*
	Meaning the VICTIM gets LESS damage!!
*/
void StatusEffect_OnTakeDamage_TakenPositive(int victim, int attacker, float &damage)
{
	if(!E_AL_StatusEffects[victim])
		return;

	float DamageRes = 1.0;
	
	static StatusEffect Apply_MasterStatusEffect;
	static E_StatusEffect Apply_StatusEffect;
	//No debuffs or status effects, skip.
	int length = E_AL_StatusEffects[victim].Length;
	for(int i; i<length; i++)
	{
		E_AL_StatusEffects[victim].GetArray(i, Apply_StatusEffect);
		AL_StatusEffects.GetArray(Apply_StatusEffect.BuffIndex, Apply_MasterStatusEffect);
		if(Apply_StatusEffect.TimeUntillOver < GetGameTime())
		{
			continue;
		}
		if(Apply_MasterStatusEffect.DamageTakenMulti == -1.0)
		{
			//Skip.
			continue;
		}
		if(!Apply_MasterStatusEffect.Positive)
		{
			//Not positive. skip.
			continue;
		}
		
		float DamageToNegate = Apply_MasterStatusEffect.DamageTakenMulti;
		if(Apply_MasterStatusEffect.OnTakeDamage_TakenFunc != INVALID_FUNCTION && Apply_MasterStatusEffect.OnTakeDamage_TakenFunc)
		{
			//We have a valid function ignore the original value.
			Call_StartFunction(null, Apply_MasterStatusEffect.OnTakeDamage_TakenFunc);
			Call_PushCell(attacker);
			Call_PushCell(victim);
			Call_PushArray(Apply_MasterStatusEffect, sizeof(Apply_MasterStatusEffect));
			Call_PushArray(Apply_StatusEffect, sizeof(Apply_StatusEffect));
			Call_Finish(DamageToNegate);
		}

		if(Apply_StatusEffect.TotalOwners[victim])
		{
			damage *= DamageToNegate;
		}
		else
		{
			DamageRes *= DamageToNegate;
		}
	}
	
	damage *= DamageRes;	
	if(length < 1)
		delete E_AL_StatusEffects[victim];
}

/*
	Me, as the attacker, will deal less damage towards other targets.
*/
void StatusEffect_OnTakeDamage_DealNegative(int victim, int attacker, float &damage)
{
	if(!E_AL_StatusEffects[attacker])
		return;
		
	float DamageRes = 1.0;
	
	static StatusEffect Apply_MasterStatusEffect;
	static E_StatusEffect Apply_StatusEffect;
	//No debuffs or status effects, skip.
	int length = E_AL_StatusEffects[attacker].Length;
	for(int i; i<length; i++)
	{
		E_AL_StatusEffects[attacker].GetArray(i, Apply_StatusEffect);
		AL_StatusEffects.GetArray(Apply_StatusEffect.BuffIndex, Apply_MasterStatusEffect);
		if(Apply_StatusEffect.TimeUntillOver < GetGameTime())
		{
			continue;
		}
		if(Apply_MasterStatusEffect.DamageDealMulti == -1.0)
		{
			//Skip.
			continue;
		}
		if(Apply_MasterStatusEffect.Positive)
		{
			//Positive, skip
			continue;
		}
		float DamageToNegate = Apply_MasterStatusEffect.DamageDealMulti;
		if(Apply_MasterStatusEffect.OnTakeDamage_DealFunc != INVALID_FUNCTION && Apply_MasterStatusEffect.OnTakeDamage_DealFunc)
		{
			//We have a valid function ignore the original value.
			Call_StartFunction(null, Apply_MasterStatusEffect.OnTakeDamage_DealFunc);
			Call_PushCell(attacker);
			Call_PushCell(victim);
			Call_PushArray(Apply_MasterStatusEffect, sizeof(Apply_MasterStatusEffect));
			Call_PushArray(Apply_StatusEffect, sizeof(Apply_StatusEffect));
			Call_Finish(DamageToNegate);
		}
		if(Apply_StatusEffect.TotalOwners[attacker])
		{
			damage *= DamageToNegate;
		}
		else
		{
			DamageRes *= DamageToNegate;
		}
	}
	
	damage *= DamageRes;	
	if(length < 1)
		delete E_AL_StatusEffects[attacker];
}

//Damage vulnerabilities, when i get HURT, this means i TAKE more damage
float StatusEffect_OnTakeDamage_TakenNegative(int victim, int attacker, float &basedamage)
{
	if(!E_AL_StatusEffects[victim])
		return 0.0;
	
	float ExtraDamageAdd;

	static StatusEffect Apply_MasterStatusEffect;
	static E_StatusEffect Apply_StatusEffect;
	//No debuffs or status effects, skip.
	int length = E_AL_StatusEffects[victim].Length;
	for(int i; i<length; i++)
	{
		E_AL_StatusEffects[victim].GetArray(i, Apply_StatusEffect);
		AL_StatusEffects.GetArray(Apply_StatusEffect.BuffIndex, Apply_MasterStatusEffect);
		if(Apply_StatusEffect.TimeUntillOver < GetGameTime())
		{
			continue;
		}
		if(Apply_MasterStatusEffect.DamageTakenMulti == -1.0)
		{
			//Skip.
			continue;
		}
		if(Apply_MasterStatusEffect.Positive)
		{
			//positive. skip.
			continue;
		}

		bool Ignore_NormalValue = false;
		if(Apply_MasterStatusEffect.OnTakeDamage_TakenFunc != INVALID_FUNCTION && Apply_MasterStatusEffect.OnTakeDamage_TakenFunc)
		{
			float DamageAdded;
			//We have a valid function ignore the original value.
			Call_StartFunction(null, Apply_MasterStatusEffect.OnTakeDamage_TakenFunc);
			Call_PushCell(attacker);
			Call_PushCell(victim);
			Call_PushArray(Apply_MasterStatusEffect, sizeof(Apply_MasterStatusEffect));
			Call_PushArray(Apply_StatusEffect, sizeof(Apply_StatusEffect));
			Call_PushCell(basedamage);
			Call_Finish(DamageAdded);
			ExtraDamageAdd += DamageAdded;
			Ignore_NormalValue = true;
		}
		if(!Ignore_NormalValue)
		{
			ExtraDamageAdd += basedamage * Apply_MasterStatusEffect.DamageTakenMulti;
		}
	}
	if(length < 1)
		delete E_AL_StatusEffects[victim];

	return ExtraDamageAdd;
}
//Damage Buffs, when i attack!
float StatusEffect_OnTakeDamage_DealPositive(int victim, int attacker, float &basedamage)
{
	if(!E_AL_StatusEffects[attacker])
		return 0.0;

	float ExtraDamageAdd;

	static StatusEffect Apply_MasterStatusEffect;
	static E_StatusEffect Apply_StatusEffect;
	//No debuffs or status effects, skip.
	int length = E_AL_StatusEffects[attacker].Length;
	for(int i; i<length; i++)
	{
		E_AL_StatusEffects[attacker].GetArray(i, Apply_StatusEffect);
		AL_StatusEffects.GetArray(Apply_StatusEffect.BuffIndex, Apply_MasterStatusEffect);
		if(Apply_StatusEffect.TimeUntillOver < GetGameTime())
		{
			continue;
		}
		if(Apply_MasterStatusEffect.DamageDealMulti == -1.0)
		{
			//Skip.
			continue;
		}
		if(!Apply_MasterStatusEffect.Positive)
		{
			//Not positive. skip.
			continue;
		}
		
		bool Ignore_NormalValue = false;
		
		if(Apply_MasterStatusEffect.OnTakeDamage_DealFunc != INVALID_FUNCTION && Apply_MasterStatusEffect.OnTakeDamage_DealFunc)
		{
			float DamageAdded;
			//We have a valid function ignore the original value.
			Call_StartFunction(null, Apply_MasterStatusEffect.OnTakeDamage_DealFunc);
			Call_PushCell(attacker);
			Call_PushCell(victim);
			Call_PushArray(Apply_MasterStatusEffect, sizeof(Apply_MasterStatusEffect));
			Call_PushArray(Apply_StatusEffect, sizeof(Apply_StatusEffect));
			Call_PushCell(basedamage);
			Call_Finish(DamageAdded);
			ExtraDamageAdd += DamageAdded;
			Ignore_NormalValue = true;
		}
		if(!Ignore_NormalValue)
		{
			ExtraDamageAdd += basedamage * Apply_MasterStatusEffect.DamageDealMulti;
		}
	}
	if(length < 1) 		
		delete E_AL_StatusEffects[attacker];

	return ExtraDamageAdd;
}

bool Status_Effects_AttackspeedBuffChange(int victim, StatusEffect Apply_MasterStatusEffect, E_StatusEffect Apply_StatusEffect, bool HasBuff = true)
{
	bool returnDo = false;
	float BuffAmount = 1.0;
	//LinkedStatusEffect
	int FlagAttackspeedLogicInternal = Apply_MasterStatusEffect.FlagAttackspeedLogic;

	if(Apply_MasterStatusEffect.Positive)
	{	
		if(Apply_StatusEffect.TotalOwners[victim])
		{
			BuffAmount = Apply_MasterStatusEffect.AttackspeedBuff;
			//We are the owner, get full buff instead.
		}
	}
	else
	{
		//For now, attackspeed debuffs dont do anythingfor scaling.
		//usually above 1.0 tho
		BuffAmount = Apply_MasterStatusEffect.AttackspeedBuff;
	}
	
	
	Status_Effects_GrantAttackspeedBonus(victim, HasBuff, BuffAmount, Apply_MasterStatusEffect.LinkedStatusEffect, FlagAttackspeedLogicInternal);
	return returnDo;
}

bool Status_Effects_GrantAttackspeedBonus(int entity, bool HasBuff, float BuffAmount, int BuffCheckerID, int FlagAttackspeedLogicInternal)
{
	//They still have the test buff
	if(IsValidClient(entity))
		Status_effects_DoAttackspeedLogic(entity, 1, HasBuff, BuffAmount, BuffCheckerID, FlagAttackspeedLogicInternal);

	return true;
}

static void Status_effects_DoAttackspeedLogic(int entity, int type, bool GrantBuff, float BuffOriginal, int BuffCheckerID, int FlagAttackspeedLogicInternal)
{
	if(type == 1)
	{
		int i, weapon;
		while(TF2_GetItem(entity, weapon, i))
		{
			//They dont even have the buff.
			if(!HasSpecificBuff(weapon, "", BuffCheckerID))
			{
				//We want to give the buff
				if(GrantBuff)
				{
					//No extra logic needed
					ApplyStatusEffect(entity, weapon, "", 9999999.9, BuffCheckerID);
					StatusEffects_SetCustomValue(weapon, BuffOriginal, BuffCheckerID);
					//inf
					if(!(FlagAttackspeedLogicInternal & BUFF_ATTACKSPEED_BUFF_DISABLE))
					{
						if(Attributes_Has(weapon, 6))
							Attributes_SetMulti(weapon, 6, BuffOriginal);	// Fire Rate
						
						if(Attributes_Has(weapon, 97))
							Attributes_SetMulti(weapon, 97, BuffOriginal);	// Reload Time

						if(Attributes_Has(weapon, 733))
							Attributes_SetMulti(weapon, 733, BuffOriginal);	// mana cost
						
						if(Attributes_Has(weapon, 8))
							Attributes_SetMulti(weapon, 8, 1.0 / BuffOriginal);	// Heal Rate
					}
					if((FlagAttackspeedLogicInternal & BUFF_PROJECTILE_SPEED))
					{
						if(Attributes_Has(weapon, 103))
							Attributes_SetMulti(weapon, 103, BuffOriginal);	// Projectile Speed
					}
					if((FlagAttackspeedLogicInternal & BUFF_PROJECTILE_RANGE))
					{
						if(Attributes_Has(weapon, 101))
							Attributes_SetMulti(weapon, 101, 1.0 / BuffOriginal);	// Projectile Range
					}
				}
			}
			else
			{
				float BuffRevert = Status_Effects_GetCustomValue(weapon, BuffCheckerID);
				//Is the buff still the same as before?
				//if it changed, we need to update it.

				//dont be null either.
				if((BuffRevert != BuffOriginal || !GrantBuff) && BuffRevert != 0.0)
				{
					//Just remove the buff it had.
					if(!(FlagAttackspeedLogicInternal & BUFF_ATTACKSPEED_BUFF_DISABLE))
					{
						if(Attributes_Has(weapon, 6))
							Attributes_SetMulti(weapon, 6, 1.0 / (BuffRevert));	// Fire Rate
						
						if(Attributes_Has(weapon, 97))
							Attributes_SetMulti(weapon, 97, 1.0 / (BuffRevert));	// Reload Time
							
						if(Attributes_Has(weapon, 733))
							Attributes_SetMulti(weapon, 733, 1.0 / (BuffRevert));	// mana cost

						if(Attributes_Has(weapon, 8))
							Attributes_SetMulti(weapon, 8, BuffRevert);	// Heal Rate
					}
					if((FlagAttackspeedLogicInternal & BUFF_PROJECTILE_SPEED))
					{
						if(Attributes_Has(weapon, 103))
							Attributes_SetMulti(weapon, 103, 1.0 / (BuffRevert));	// Projectile Speed
					}
					if((FlagAttackspeedLogicInternal & BUFF_PROJECTILE_RANGE))
					{
						if(Attributes_Has(weapon, 101))
							Attributes_SetMulti(weapon, 101, BuffOriginal);	// Projectile Range
					}
				
					RemoveSpecificBuff(weapon, "", BuffCheckerID, false);
				}
				if(GrantBuff && BuffRevert != BuffOriginal)
				{
					//No extra logic needed
					ApplyStatusEffect(entity, weapon, "", 9999999.9, BuffCheckerID);
					StatusEffects_SetCustomValue(weapon, BuffOriginal, BuffCheckerID);
					//inf
					if(!(FlagAttackspeedLogicInternal & BUFF_ATTACKSPEED_BUFF_DISABLE))
					{
						if(Attributes_Has(weapon, 6))
							Attributes_SetMulti(weapon, 6, BuffOriginal);	// Fire Rate
						
						if(Attributes_Has(weapon, 97))
							Attributes_SetMulti(weapon, 97, BuffOriginal);	// Reload Time

						if(Attributes_Has(weapon, 733))
							Attributes_SetMulti(weapon, 733, BuffOriginal);	// mana cost

						if(Attributes_Has(weapon, 8))
							Attributes_SetMulti(weapon, 8, 1.0 / BuffOriginal);	// Heal Rate
					}
					if((FlagAttackspeedLogicInternal & BUFF_PROJECTILE_SPEED))
					{
						if(Attributes_Has(weapon, 103))
							Attributes_SetMulti(weapon, 103, BuffOriginal);	// Projectile Speed
					}
					if((FlagAttackspeedLogicInternal & BUFF_PROJECTILE_RANGE))
					{
						if(Attributes_Has(weapon, 101))
							Attributes_SetMulti(weapon, 101, 1.0 / BuffOriginal);	// Projectile Range
					}
				}
			}
		}
	}
}

void StatusEffects_HudAbove(int victim, char[] HudAbove, int SizeOfChar)
{
	if(!E_AL_StatusEffects[victim])
		return;
		
	static StatusEffect Apply_MasterStatusEffect;
	static E_StatusEffect Apply_StatusEffect;
	//No debuffs or status effects, skip.
	int length = E_AL_StatusEffects[victim].Length;
	for(int i; i<length; i++)
	{
		E_AL_StatusEffects[victim].GetArray(i, Apply_StatusEffect);
		AL_StatusEffects.GetArray(Apply_StatusEffect.BuffIndex, Apply_MasterStatusEffect);
		if(Apply_StatusEffect.TimeUntillOver < GetGameTime())
		{
			continue;
		}
		if(!Apply_MasterStatusEffect.AboveEnemyDisplay[0])
			continue;

		Format(HudAbove, SizeOfChar, "%s%s", Apply_MasterStatusEffect.AboveEnemyDisplay, HudAbove);
	}
	if(length < 1) 		
		delete E_AL_StatusEffects[victim];
}

//Speed Buff modif!
stock void StatusEffect_SpeedModifier(int victim, float &SpeedModifPercentage)
{
	if(!E_AL_StatusEffects[victim])
		return;

	//No change
	static StatusEffect Apply_MasterStatusEffect;
	static E_StatusEffect Apply_StatusEffect;

	static float TotalSlowdown;
	TotalSlowdown = SpeedModifPercentage;

	bool SpeedWasNerfed = false;
	int length = E_AL_StatusEffects[victim].Length;
	for(int i; i<length; i++)
	{
		E_AL_StatusEffects[victim].GetArray(i, Apply_StatusEffect);
		AL_StatusEffects.GetArray(Apply_StatusEffect.BuffIndex, Apply_MasterStatusEffect);
		if(Apply_StatusEffect.TimeUntillOver < GetGameTime())
		{
			continue;
		}
		if(Apply_MasterStatusEffect.MovementspeedModif == -1.0)
		{
			//Skip.
			continue;
		}
		float SpeedModif = Apply_MasterStatusEffect.MovementspeedModif;
		if(Apply_MasterStatusEffect.Status_SpeedFunc != INVALID_FUNCTION && Apply_MasterStatusEffect.Status_SpeedFunc)
		{
			//We have a valid function ignore the original value.
			Call_StartFunction(null, Apply_MasterStatusEffect.Status_SpeedFunc);
			Call_PushCell(victim);
			Call_PushArray(Apply_MasterStatusEffect, sizeof(Apply_MasterStatusEffect));
			Call_PushArray(Apply_StatusEffect, sizeof(Apply_StatusEffect));
			Call_Finish(SpeedModif);
		}
		if(Apply_MasterStatusEffect.Positive)
		{
			//If its a positive buff, do No penalty
			SpeedModifPercentage *= SpeedModif;
		}
		else
		{
			if(!HasSpecificBuff(victim, "Fluid Movement"))
			{
				SpeedWasNerfed = true;
				TotalSlowdown *= SpeedModif;
			}
		}
	}
	//speed debuffs will now behave the excat same as damage buffs
	if(SpeedWasNerfed)
		SpeedModifPercentage -= TotalSlowdown;

	//No magical backwards shit
	if(SpeedModifPercentage <= 0.0)
	{
		SpeedModifPercentage = 0.0;
	}
	if(length < 1) 		
		delete E_AL_StatusEffects[victim];
}

stock void StatusEffects_SetCustomValue(int victim, float NewBuffValue, int Index)
{
	if(!E_AL_StatusEffects[victim])
		return;

	static StatusEffect Apply_MasterStatusEffect;
	static E_StatusEffect Apply_StatusEffect;
	int ArrayPosition = E_AL_StatusEffects[victim].FindValue(Index , E_StatusEffect::BuffIndex);
	if(ArrayPosition != -1)
	{
		E_AL_StatusEffects[victim].GetArray(ArrayPosition, Apply_StatusEffect);
		AL_StatusEffects.GetArray(Apply_StatusEffect.BuffIndex, Apply_MasterStatusEffect);
		if(Apply_StatusEffect.TimeUntillOver >= GetGameTime())
		{
			//We always set it instantly.
			Apply_StatusEffect.DataForUse = NewBuffValue;
			E_AL_StatusEffects[victim].SetArray(ArrayPosition, Apply_StatusEffect);
		}
	}
	if(E_AL_StatusEffects[victim].Length < 1)
		delete E_AL_StatusEffects[victim];
}

stock float Status_Effects_GetCustomValue(int victim, int Index)
{
	float BuffValuereturn = 1.0;
	if(!E_AL_StatusEffects[victim])
		return BuffValuereturn;

	static StatusEffect Apply_MasterStatusEffect;
	static E_StatusEffect Apply_StatusEffect;
	int ArrayPosition = E_AL_StatusEffects[victim].FindValue(Index , E_StatusEffect::BuffIndex);
	if(ArrayPosition != -1)
	{
		E_AL_StatusEffects[victim].GetArray(ArrayPosition, Apply_StatusEffect);
		AL_StatusEffects.GetArray(Apply_StatusEffect.BuffIndex, Apply_MasterStatusEffect);
		if(Apply_StatusEffect.TimeUntillOver >= GetGameTime())
		{
			BuffValuereturn = Apply_StatusEffect.DataForUse;
			//add scaling?
			if(Apply_StatusEffect.TotalOwners[victim])
			{
				BuffValuereturn = Apply_StatusEffect.DataForUse;
				//We are the owner, get full buff instead.
			}
			E_AL_StatusEffects[victim].SetArray(ArrayPosition, Apply_StatusEffect);
		}
	}
	if(E_AL_StatusEffects[victim].Length < 1)
		delete E_AL_StatusEffects[victim];

	return BuffValuereturn;
}

void StatusEffect_OnTakeDamagePostVictim(int victim, int attacker, float damage)
{
	if(!E_AL_StatusEffects[victim])
		return;
	
	static StatusEffect Apply_MasterStatusEffect;
	static E_StatusEffect Apply_StatusEffect;
	//No debuffs or status effects, skip.
	int length = E_AL_StatusEffects[victim].Length;
	for(int i; i<length; i++)
	{
		E_AL_StatusEffects[victim].GetArray(i, Apply_StatusEffect);
		AL_StatusEffects.GetArray(Apply_StatusEffect.BuffIndex, Apply_MasterStatusEffect);
		if(Apply_StatusEffect.TimeUntillOver < GetGameTime())
		{
			continue;
		}
		if(Apply_MasterStatusEffect.OnTakeDamage_PostVictim != INVALID_FUNCTION && Apply_MasterStatusEffect.OnTakeDamage_PostVictim)
		{
			//We have a valid function ignore the original value.
			Call_StartFunction(null, Apply_MasterStatusEffect.OnTakeDamage_PostVictim);
			Call_PushCell(attacker);
			Call_PushCell(victim);
			Call_PushFloat(damage);
			Call_PushArray(Apply_MasterStatusEffect, sizeof(Apply_MasterStatusEffect));
			Call_PushArray(Apply_StatusEffect, sizeof(Apply_StatusEffect));
			Call_Finish();
		}
	}

	if(length < 1)
		delete E_AL_StatusEffects[victim];
}
void StatusEffect_OnTakeDamagePostAttacker(int victim, int attacker, float damage)
{
	if(!E_AL_StatusEffects[attacker])
		return;
	
	static StatusEffect Apply_MasterStatusEffect;
	static E_StatusEffect Apply_StatusEffect;
	//No debuffs or status effects, skip.
	int length = E_AL_StatusEffects[attacker].Length;
	for(int i; i<length; i++)
	{
		E_AL_StatusEffects[attacker].GetArray(i, Apply_StatusEffect);
		AL_StatusEffects.GetArray(Apply_StatusEffect.BuffIndex, Apply_MasterStatusEffect);
		if(Apply_StatusEffect.TimeUntillOver < GetGameTime())
		{
			continue;
		}
		if(Apply_MasterStatusEffect.OnTakeDamage_PostAttacker != INVALID_FUNCTION && Apply_MasterStatusEffect.OnTakeDamage_PostAttacker)
		{
			//We have a valid function ignore the original value.
			Call_StartFunction(null, Apply_MasterStatusEffect.OnTakeDamage_PostAttacker);
			Call_PushCell(attacker);
			Call_PushCell(victim);
			Call_PushFloat(damage);
			Call_PushArray(Apply_MasterStatusEffect, sizeof(Apply_MasterStatusEffect));
			Call_PushArray(Apply_StatusEffect, sizeof(Apply_StatusEffect));
			Call_Finish();
		}
	}

	if(length < 1)
		delete E_AL_StatusEffects[attacker];
}

/////
/*
    STATUS EFFECTS
*/
/////
void InitStatusEffects()
{
	//First delete everything
	delete AL_StatusEffects;
	AL_StatusEffects = new ArrayList(sizeof(StatusEffect));

	DeleteStatusEffectsFromAll();
	//clear all existing ones

	StatusEffects_MercDmgBoost();
    StatusEffects_LastmanBuff();
}

void StatusEffects_MercDmgBoost()
{
	StatusEffect data;
	strcopy(data.BuffName, sizeof(data.BuffName), "Merc Group Boost");
	strcopy(data.AboveEnemyDisplay, sizeof(data.AboveEnemyDisplay), ""); // Don't display an icon on their head for this one
	//-1.0 means unused
	data.DamageTakenMulti 			= -1.0;
	data.DamageDealMulti			= 0.05;
	data.MovementspeedModif			= -1.0;
	data.Positive 					= true;
	data.Slot						= 0; // 0 means ignored
	data.SlotPriority				= 0; // If its higher, then the lower version is entirely ignored.
	StatusEffect_AddGlobal(data);
}

void StatusEffects_LastmanBuff()
{
	StatusEffect data;
	strcopy(data.BuffName, sizeof(data.BuffName), "Last Man Standing");
	strcopy(data.AboveEnemyDisplay, sizeof(data.AboveEnemyDisplay), "◈");
	//-1.0 means unused
	data.DamageTakenMulti 			= 0.85;
	data.DamageDealMulti			= 0.2;
	data.MovementspeedModif			= -1.0;
    data.AttackspeedBuff			= (1.0 / 1.1);
	data.Positive 					= true;
	data.Slot						= 0; // 0 means ignored
	data.SlotPriority				= 0; // If its higher, then the lower version is entirely ignored.
	StatusEffect_AddGlobal(data);

    strcopy(data.BuffName, sizeof(data.BuffName), "Last Merc Standing");
	strcopy(data.AboveEnemyDisplay, sizeof(data.AboveEnemyDisplay), "◈M");
	//-1.0 means unused
	data.DamageTakenMulti 			= 0.75;
	data.DamageDealMulti			= 0.35;
	data.MovementspeedModif			= -1.0;
    data.AttackspeedBuff			= (1.0 / 1.15);
	data.Positive 					= true;
	data.Slot						= 0; // 0 means ignored
	data.SlotPriority				= 0; // If its higher, then the lower version is entirely ignored.
	StatusEffect_AddGlobal(data);
}