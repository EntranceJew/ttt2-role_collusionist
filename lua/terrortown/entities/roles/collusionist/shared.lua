---@diagnostic disable: missing-parameter
if SERVER then
	AddCSLuaFile()

	resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_col.vmt")
end

function ROLE:PreInitialize()
	self.color = Color(248, 200, 220, 255)

	self.abbr = "col" -- abbreviation
	self.radarColor = Color(248, 200, 220) -- color if someone is using the radar
	self.surviveBonus = 0 -- bonus multiplier for every survive while another player was killed
	self.scoreKillsMultiplier = 1 -- multiplier for kill of player of another team
	self.scoreTeamKillsMultiplier = -8 -- multiplier for teamkill
	self.preventWin = true -- set true if role can't win (maybe because of own / special win conditions)
	self.defaultTeam = TEAM_COLLUSIONIST -- the team name: roles with same team name are working together
	self.defaultEquipment = SPECIAL_EQUIPMENT -- here you can set up your own default equipment

	self.conVarData = {
		pct = 0.15, -- necessary: percentage of getting this role selected (per player)
		maximum = 1, -- maximum amount of roles in a round
		minPlayers = 5, -- minimum amount of players until this role is able to get selected
		random = 30,
		credits = 1, -- the starting credits of a specific role
		togglable = true, -- option to toggle a role for a client if possible (F1 menu)
		shopFallback = SHOP_DISABLED,
	}
end

--#region CVars
if SERVER then
---@diagnostic disable-next-line: param-type-mismatch
	CreateConVar("ttt2_collusionist_donor_health", "1", {FCVAR_NOTIFY, FCVAR_ARCHIVE})
---@diagnostic disable-next-line: param-type-mismatch
	CreateConVar("ttt2_collusionist_respawn_health", "100", {FCVAR_NOTIFY, FCVAR_ARCHIVE})


---@diagnostic disable-next-line: param-type-mismatch
	CreateConVar("ttt2_collusionist_entity_damage", "1", {FCVAR_NOTIFY, FCVAR_ARCHIVE})
---@diagnostic disable-next-line: param-type-mismatch
	CreateConVar("ttt2_collusionist_environmental_damage", "1", {FCVAR_NOTIFY, FCVAR_ARCHIVE})
---@diagnostic disable-next-line: param-type-mismatch
	CreateConVar("ttt2_collusionist_respawn", "1", {FCVAR_NOTIFY, FCVAR_ARCHIVE})
---@diagnostic disable-next-line: param-type-mismatch
	CreateConVar("ttt2_collusionist_respawn_delay", "3", {FCVAR_NOTIFY, FCVAR_ARCHIVE})
---@diagnostic disable-next-line: param-type-mismatch
	CreateConVar("ttt2_collusionist_reveal_mode", "0", {FCVAR_NOTIFY, FCVAR_ARCHIVE})

---@diagnostic disable-next-line: param-type-mismatch
	CreateConVar("ttt2_collusionist_kill_policing_roles", "1", {FCVAR_NOTIFY, FCVAR_ARCHIVE})
end

if CLIENT then
	function ROLE:AddToSettingsMenu(parent)
		local form = vgui.CreateTTT2Form(parent, "header_roles_additional")

		-- form:MakeCheckBox({
		-- 	serverConvar = "ttt2_collusionist_killer_health",
		-- 	label = "label_ttt2_collusionist_killer_health"
		-- })


		form:MakeSlider({
			serverConvar = "ttt2_collusionist_donor_health",
			min = 0,
			max = 100,
			default = 1,
			decimal = 0,
			label = "label_collusionist_donor_health",
		})
		form:MakeSlider({
			serverConvar = "ttt2_collusionist_respawn_health",
			min = 0,
			max = 100,
			default = 100,
			decimal = 0,
			label = "label_collusionist_respawn_health"
		})

		form:MakeCheckBox({
			serverConvar = "ttt2_collusionist_entity_damage",
			label = "label_collusionist_entity_damage"
		})
		form:MakeCheckBox({
			serverConvar = "ttt2_collusionist_environmental_damage",
			label = "label_collusionist_environmental_damage",
		})
		form:MakeCheckBox({
			serverConvar = "ttt2_collusionist_respawn",
			label = "label_collusionist_respawn",
		})
		form:MakeSlider({
			serverConvar = "ttt2_collusionist_respawn_delay",
			min = 0,
			max = 60,
			decimal = 0,
			label = "label_collusionist_respawn_delay"
		})
		form:MakeComboBox({
			serverConvar = "ttt2_collusionist_reveal_mode",
			label = "label_collusionist_reveal_mode",
			choices = {
				"0 - Never reveal the collusionist has changed team",
				"1 - Only alert the detective or traitors the collusionist has now joined",
				"2 - Alert all of the collusionists new team members",
				"3 - Alert everyone of the collusionists new team",
			},
			default = 0,
		})

		form:MakeCheckBox({
			serverConvar = "ttt2_collusionist_kill_policing_roles",
			label = "label_collusionist_kill_policing_roles"
		})
	end
end
--#endregion CVars

if SERVER then
	local function TakeNoDamage(ply, attacker, role)
		if not IsValid(ply) or ply:GetSubRole() ~= role then return end

		if not IsValid(attacker) or not attacker:IsPlayer() or attacker ~= ply then return end

		print("Blocking " .. role .. " taking damage")
		return true -- true to block damage event
	end

	-- Handle the attacker only damaging other players
	local function DealNoDamage(ply, attacker, role)
		if not IsValid(ply) or not IsValid(attacker) or not attacker:IsPlayer() or attacker:GetSubRole() ~= role then return end
		if SpecDM and (ply.IsGhost and ply:IsGhost() or (attacker.IsGhost and attacker:IsGhost())) then return end

		print("Blocking " .. role .. " damaging others")
		return true -- true to block damage event
	end

	-- Handle the attacker only damaging entities
	local function EntityDamage(ply, dmginfo, role)
		local attacker = dmginfo:GetAttacker()
		local roleName = (role == ROLE_COLLUSIONIST and "collusionist") or role

		if not IsValid(attacker) or not attacker:IsPlayer() or attacker:GetSubRole() ~= role then return end

		-- Allow the player to damage entities unless convar is false
		if GetConVar("ttt2_" .. roleName .. "_entity_damage"):GetBool() then return end

		print("Blocking " .. roleName .. " entity damage")
		return true -- true to block damage event

	end

	-- Handle the ply only taking environmental damage
	local function TakeEnvironmentalDamage(ply, dmginfo, role)
		local attacker = dmginfo:GetAttacker()
		local roleName = (role == ROLE_COLLUSIONIST and "collusionist") or role

		if not IsValid(ply) or not ply:IsPlayer() or ply:GetSubRole() ~= role then return end
		if IsValid(attacker) and attacker:IsPlayer() then return end -- we dont want to consider player damage at all here

		-- Allow the player to take environmental damage unless convar is false
		if GetConVar("ttt2_" .. roleName .. "_environmental_damage"):GetBool() and (dmginfo:IsDamageType(DMG_BLAST + DMG_BURN + DMG_CRUSH + DMG_FALL + DMG_DROWN)) then return end

		print("Blocking " .. roleName .. " taking environmental damage")
		return true -- true to block damage event

	end

	local function CollusionistRevive(ply)
		ply:Revive(
			0,
		  	function()	-- @param[opt] function OnRevive The @{function} that should be run if the @{Player} revives
				ply:ResetConfirmPlayer()
				SendFullStateUpdate()
		  	end
		)
	end

	hook.Add("TTT2SpecialRoleSyncing", "TTT2RoleCollusionist", function(ply, tbl)
		if ply and not ply:HasTeam(TEAM_TRAITOR) or ply:GetSubRoleData().unknownTeam or GetRoundState() == ROUND_POST then return end

		for collusionist in pairs(tbl) do
			if not collusionist:IsTerror() or collusionist == ply then
				continue
			end
			if ply:GetSubRole() ~= ROLE_COLLUSIONIST and collusionist:GetSubRole() == ROLE_COLLUSIONIST then
				if not collusionist:Alive() then
					continue
				end
				if ply:GetTeam() ~= TEAM_JESTER then
					tbl[collusionist] = {ROLE_JESTER, TEAM_JESTER}
				else
					tbl[collusionist] = {ROLE_COLLUSIONIST, TEAM_JESTER}
				end
			end
		end
	end)

	hook.Add("TTT2ModifyRadarRole", "TTT2ModifyRadarRoleCollusionist", function(ply, target)
		if ply:HasTeam(TEAM_TRAITOR) and target:GetSubRole() == ROLE_COLLUSIONIST then
			return ROLE_JESTER, TEAM_JESTER
		end
	end)

	hook.Add("WeaponEquip", "CollusionistItemEquip", function(weapon, ply)
		if weapon.CanBuy and not weapon.AutoSpawnable then
			if not weapon.BoughtBy then
				weapon.BoughtBy = ply
			elseif ply:GetSubRole() == ROLE_COLLUSIONIST then
				local donator = weapon.BoughtBy
				local role = donator:GetSubRole()
				local team = weapon.BoughtBy:GetTeam()

				print("Collusionist has picked up a " .. tostring(weapon) .. " dropped by " .. tostring(donator) .. " who has this team " .. tostring(team))

				if not donator:IsActive() or (GetConVar("ttt2_collusionist_kill_policing_roles"):GetBool() and donator:GetSubRoleData().isPolicingRole) then return end

				donator:PrintMessage(HUD_PRINTTALK, "You have colluded with the collusionist!")
				-- donator:PrintMessage(HUD_PRINTCENTER, "You have colluded with the collusionist!")

				ply:SetRole(role, team) -- added the team parameter mainly for the Jackal right now
				donator:Kill()

				roles.JESTER.SpawnJesterConfetti(donator)

				SendFullStateUpdate()
				ply:UpdateTeam(team)
				timer.Simple(0.5, function() SendFullStateUpdate() end)

				-- local mode = GetConVar("ttt2_collusionist_reveal_mode"):GetInt()
				-- local players = player.GetAll()
				-- for i = 1, #players do
					-- local v = players[i]
					-- if (mode ~= 0 and mode == 1 and (role == ROLE_INNOCENT and v:GetSubRole() == ROLE_DETECTIVE) or (role == ROLE_TRAITOR and v:GetTeam() == TEAM_TRAITOR)) or (mode == 2 and ply:GetTeam() == v:GetTeam()) or (mode == 3) then
						-- v:PrintMessage(HUD_PRINTTALK, "The collusionist has joined the " .. teamString)
						-- v:PrintMessage(HUD_PRINTCENTER, "The collusionist has joined the " .. teamString)
					-- end
				-- end
			end
		end
	end)

	-- Collusionist doesnt deal or take any damage in relation to players
	hook.Add("PlayerTakeDamage", "CollusionistNoDamage", function(ply, inflictor, killer, amount, dmginfo)
		if TakeNoDamage(ply, killer, ROLE_COLLUSIONIST) or DealNoDamage(ply, killer, ROLE_COLLUSIONIST) then
			dmginfo:ScaleDamage(0)
			dmginfo:SetDamage(0)
			return
		end
	end)

	-- Check if the collusionist can damage entities or be damaged by environmental effects
	hook.Add("EntityTakeDamage", "CollusionistEntityNoDamage", function(ply, dmginfo)
		if EntityDamage(ply, dmginfo, ROLE_COLLUSIONIST) or TakeEnvironmentalDamage(ply, dmginfo, ROLE_COLLUSIONIST) then
			dmginfo:ScaleDamage(0)
			dmginfo:SetDamage(0)
			return
		end
	end)

	hook.Add("PlayerDeath", "CollusionistDeath", function(victim, infl, attacker)
		if victim:GetSubRole() == ROLE_COLLUSIONIST and IsValid(attacker) and attacker:IsPlayer() then
			if victim == attacker then return end -- Suicide so do nothing

			if GetConVar("ttt2_collusionist_respawn"):GetBool() then
				local delay = GetConVar("ttt2_collusionist_respawn_delay"):GetInt()
				if delay > 0 then
					victim:PrintMessage(HUD_PRINTTALK, "You were killed but will respawn in " .. delay .. " seconds.")
				else
					victim:PrintMessage(HUD_PRINTTALK, "You were killed but are about to respawn.")
					-- Introduce a slight delay to prevent player getting stuck as a spectator
					delay = 0.1
				end
				timer.Simple(delay, function()
					CollusionistRevive(victim)
				end)
			end
		end
	end)
end