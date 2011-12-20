
void sm_Init() {
	g_soulmates = cvar("g_explosive_freezetag_soulmates");
	DEPENDON(g_soulmates)
	sm_Clear();
	precache_sound("kh/capture.wav");
}

void sm_Attach(entity host, entity slave) {
	DEPENDON(g_soulmates)
	
	while(host.soulmate)
		host = host.soulmate;
	
	if(host == slave || host == slave.soulmate || slave == host.soulmate)
		return;
	
	host.soulmate = slave;
	slave.movetype = MOVETYPE_FOLLOW;
	slave.aiment = host.sment;
	slave.smhost = host;
	slave.sm_canattach = 0;
	
	FOR_EACH_PLAYER(other) if(other.team != slave.team)
		bigprint_spec(other, "^1warning!", strcat(slave.netname, " ^7 is now ", host.netname, "^7's soulmate!"), 2);
		
	centerprint_spec(slave, strcat("You are now ", host.netname, "^7's soulmate!"));
	centerprint_spec(host, strcat(slave.netname, "^7 is now your soulmate!"));
	
	string s = strcat(slave.netname, " ^7is now ", host.netname, "^7's soulmate!\n");
	FOR_EACH_PLAYER(other)
		centerprint_spec(other, s);
	bprint(s);
	
	play2all("kh/capture.wav");
}

void sm_Detach(entity host) {
	DEPENDON(g_soulmates)
	
	entity slave = host.soulmate;
	
	if(!slave)
		return;
	
	slave.movetype = MOVETYPE_WALK;
	slave.aiment = world;
	slave.smhost = world;
	slave.velocity = '0 0 0';
	host.soulmate = world;
}

void sm_SMEntThink() {
	setorigin(self, self.owner.origin + '0 0 0.49' * self.owner.size_z);
	self.nextthink = time;
}

void sm_FixSMEnt(entity p) {
	entity e = spawn();
	e.owner = p;
	e.classname = "sm_ent";
	e.think = sm_SMEntThink;
	e.nextthink = time;
	p.sment = e;
}

void sm_Frame() {
	DEPENDON(g_soulmates)
	
	if(self.sm_canattach && !sm_IsSoulMate(self) && time > self.sm_nextnotify) {
		bigprint_spec(self, "you've got a soul gem!", "Collide with a teammate to connect!", 2);
		self.sm_nextnotify = time + 5;
	}
	
	if(!self.sment)
		sm_FixSMEnt(self);
		
	if(sm_IsSoulMate(self)) {
		if(!self.aiment) {	// some weird bug
			self.aiment = self.smhost.sment;
		}
		
		if(self.BUTTON_USE) {
			if(cvar("g_explosive_freezetag_soulmates_allow_detach")) {
				bprint(self.netname, " ^7has detached from ", self.smhost.netname, "\n");
				
				sm_Detach(self.smhost);
				self.sm_canattach = 1;
				self.sm_attachblock = time + 2;
				
				makevectors(self.angles);
				self.velocity = self.velocity - v_forward * 100;
				self.velocity_z = 400;
			} else {
				sprint(self, "^1You are not allowed to detach on this server\n");
			}
		}
		
		return;
	}
	
	if(!self.sm_canattach)
		return;
	
	if(time < self.sm_attachblock)
		return;
	
	//if(self.soulmate)
	//	return;
	
	vector sm_extra_size = '1 1 1' * 10;
	
	FOR_EACH_PLAYER(other) if(!other.freezetag_frozen) if(self != other) if(self.team == other.team) {
		if(boxesoverlap(self.absmin - sm_extra_size, self.absmax + sm_extra_size, other.absmin, other.absmax)) {
			sm_Attach(other, self);
		}
	}
}

void sm_SpawnSoulGems(float theteam) {
	float count, gems, i;
	
	FOR_EACH_PLAYER(other) if(other.team == theteam)
		++count;
	gems = max(1, ceil(count / cvar("g_explosive_freezetag_soulmates_players_per_gem")));
	
	for(i = 0; i < gems; ++i)
		sm_SpawnSoulGem(theteam);
}

void sm_Clear() {
	DEPENDON(g_soulmates)
	
	FOR_EACH_PLAYER(other)
		if(other.soulmate)
			sm_Detach(other);
	
	for(other = world; (other = find(other, classname, "sm_soulgem")); )
		sm_RemoveSoulGem(other);
	
	FOR_EACH_PLAYER(other)
		other.sm_canattach = 0;
	
	sm_SpawnSoulGems(COLOR_TEAM1);
	sm_SpawnSoulGems(COLOR_TEAM2);
	
	if(ft_teams > 2)
		sm_SpawnSoulGems(COLOR_TEAM3);
		
	if(ft_teams > 3)
		sm_SpawnSoulGems(COLOR_TEAM4);
}

void sm_RemovePlayer() {
	if(self.soulmate)
		self.soulmate.sm_canattach = 1;
	
	sm_Detach(self);
	
	FOR_EACH_CLIENT(other)
		if(other.soulmate == self)
			sm_Detach(other);
}

float sm_IsSoulMate(entity p) {
	return p.movetype == MOVETYPE_FOLLOW && p.smhost;
}

vector sm_SoulGemColormod(float theteam)
{
	switch(theteam)
	{
		case COLOR_TEAM1:
			return '1 .8 .8';
		case COLOR_TEAM2:
			return '.8 .8 1';
		case COLOR_TEAM3:
			return '1 1 .8';
		case COLOR_TEAM4:
			return '1 .8 1';
		default:
			return '.2 .2 .2';
	}
}

vector sm_SoulGemColormod2(float theteam)
{
	switch(theteam)
	{
		case COLOR_TEAM1:
			return '1 .4 .4';
		case COLOR_TEAM2:
			return '.4 .4 1';
		case COLOR_TEAM3:
			return '1 1 .4';
		case COLOR_TEAM4:
			return '1 .4 1';
		default:
			return '.1 .1 .1';
	}
}

void sm_SoulGem_Touch() {
	if(self.gem_pickedup)
		return;
	
	if(other.classname != "player")
		return;
	
	if(other.team != self.team)
		return;
	
	if(other.sm_canattach)
		return;
		
	self.colormod = sm_SoulGemColormod(-self.team);
	self.enemy.colormod = sm_SoulGemColormod2(-self.team);
	self.gem_pickedup = 1;
	
	other.sm_canattach = 1;
	play2all("kh/capture.wav");
	
	string s = strcat(other.netname, " ^2picked up a soul gem!");
	FOR_EACH_PLAYER(other)
		centerprint_spec(other, s);
	bprint(s, "\n");
}

void sm_RemoveSoulGem(entity gem) {
	if(gem.enemy)
		remove(gem.enemy);
	remove(gem);
}

void sm_SoulGem_Reset() {
	self.gem_pickedup = 0;
	self.alpha = self.enemy.alpha = 0.8;
	self.colormod = sm_SoulGemColormod(self.team);
	self.enemy.colormod = sm_SoulGemColormod2(self.team);
}

void sm_SpawnSoulGem(float theteam) {
	local entity e;
	e = spawn();
	e.classname = "sm_soulgem";
	e.target = "###item###";
	e.team = theteam;
	e.movetype = MOVETYPE_NONE;
	e.touch = sm_SoulGem_Touch;
	e.solid = SOLID_TRIGGER;
	e.flags = FL_ITEM;
	e.reset2 = sm_SoulGem_Reset;
	setmodel(e, "models/runematch/rune.mdl");
	setsize(e, '0 0 -35', '0 0 0');
	
	e.enemy = spawn();
	e.enemy.enemy = e;
	e.enemy.classname = "sm_soulgem_effect";
	setmodel(e.enemy, "models/runematch/curse.mdl");
	e.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP;
	setattachment(e.enemy, e, "");
	
	entity spot = Spawn_WeightedPoint(findchain(classname, "info_player_deathmatch"), 1, 1, 1);
	setorigin(e, spot.origin);
	
	if(!move_out_of_solid(e))
		bprint("\x01^1WARNING: ^7failed to move soulgem out of solid, expect weird shit and breakages\n");
	
	local entity oldself;
	oldself = self;
	self = e;
	droptofloor();
	self = oldself;

	e.colormod = sm_SoulGemColormod(theteam);
	e.enemy.colormod = sm_SoulGemColormod2(theteam);

	e.alpha = e.enemy.alpha = 0.8;
	e.effects = e.enemy.effects = (EF_ADDITIVE | EF_FULLBRIGHT);
}
