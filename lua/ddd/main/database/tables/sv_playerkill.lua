local playerIdTable = DDD.Database.Tables.PlayerId
local weaponIdTable = DDD.Database.Tables.WeaponId
local mapIdTable = DDD.Database.Tables.MapId
local roundIdTable = DDD.Database.Tables.RoundId

local roles = DDD.Database.Roles

local columns = {id = "INTEGER PRIMARY KEY",
                 round_id = "INTEGER NOT NULL",
                 round_time = "REAL NOT NULL",
                 victim_id = "INTEGER NOT NULL", 
                 attacker_id = "INTEGER NOT NULL",
                 weapon_id = "INTEGER NOT NULL"
               }
      
local foreignKeyTable = DDD.Database.ForeignKeyTable:new()
foreignKeyTable:addConstraint("round_id", roundIdTable, "id")
foreignKeyTable:addConstraint("victim_id", playerIdTable, "id")
foreignKeyTable:addConstraint("attacker_id", playerIdTable, "id")
foreignKeyTable:addConstraint("weapon_id", weaponIdTable, "id")
  
local playerKillTable = DDD.SqlTable:new("ddd_player_kill", columns, foreignKeyTable)

playerIdTable:addIndex("roundIdIndex", {"round_id"})
playerIdTable:addIndex("victimIndex", {"victim_id"})
playerIdTable:addIndex("attackerIndex", {"attacker_id"})
playerIdTable:addIndex("attackerVsVictimIndex", {"attacker_id, victim_id"})
playerIdTable:addIndex("killsWithWeaponIndex", {"attacker_id, weapon_id"})
playerIdTable:addIndex("deathsFromWeaponIndex", {"victim_id, weapon_id"})

function playerKillTable:addKill(victimId, attackerId, weaponId)
  local queryTable = {
    round_id = self:getForeignTableByColumn("round_id"):getCurrentRoundId(),
    victim_id = victimId,
    attacker_id = attackerId,
    weapon_id = weaponId,
    round_time = DDD.CurrentRound:getCurrentRoundTime()  
  }
  return self:insertTable(queryTable)
end

function playerKillTable:getKillsAsRole(playerId, roleId)
  local query = [[SELECT kill.*, victim_roles.role_id as victim_role, attacker_roles.role_id as attacker_role
                  FROM ]] .. self.tableName .. [[ AS kill
                  LEFT JOIN ddd_round_roles AS victim_roles 
                  ON kill.round_id == victim_roles.round_id
                  AND kill.victim_id == victim_roles.player_id
                  LEFT JOIN ddd_round_roles AS attacker_roles
                  ON kill.round_id == attacker_roles.round_id
                  AND kill.attacker_id == attacker_roles.player_id
                  WHERE kill.attacker_id == ]] .. tostring(playerId) .. [[
                  AND attacker_roles.role_id == ]] .. tostring(roleId)
  return sql.Query(query)
end

function playerKillTable:getKillsAsTraitor(playerId)
  playerKillTable:getKillsAsRole(playerId, 0)
end

local function countResult(funcName, result)
  if (result == nil) then
    DDD.Logging.logDebug("sv_playerkills.lua - " .. funcName .. ": The query returned no information.")
    return -1
  elseif (result == false) then
    DDD.Logging.logError("sv_playerkills.lua - " .. funcName .. ": An error occured. Error was: " .. sql.LastError())
    return 0
else 
  return tonumber(result[1]["count"])
  end
end

function playerKillTable:getTotalKills(playerId)
  local query = [[SELECT COUNT(*) AS count
                  FROM ]] .. self.tableName .. [[ AS kill
                  LEFT JOIN ddd_round_roles AS victim_roles 
                  ON kill.round_id == victim_roles.round_id
                  AND kill.victim_id == victim_roles.player_id
                  LEFT JOIN ddd_round_roles AS attacker_roles
                  ON kill.round_id == attacker_roles.round_id
                  AND kill.attacker_id == attacker_roles.player_id
                  WHERE kill.attacker_id == ]] .. tostring(playerId)
                  
  local result = sql.Query(query)
  return countResult("getTotalKills", result)
end

function playerKillTable:getTotalDeaths(playerId)
  local query = [[SELECT COUNT(*) AS count
                  FROM ]] .. self.tableName .. [[ AS kill
                  LEFT JOIN ddd_round_roles AS victim_roles 
                  ON kill.round_id == victim_roles.round_id
                  AND kill.victim_id == victim_roles.player_id
                  LEFT JOIN ddd_round_roles AS attacker_roles
                  ON kill.round_id == attacker_roles.round_id
                  AND kill.attacker_id == attacker_roles.player_id
                  WHERE kill.victim_id == ]] .. tostring(playerId)

  local result = sql.Query(query)
  return countResult("getTotalDeaths", result)
end

function playerKillTable:getRoleKills(playerId, playerRole, victimRole)
  local query = [[SELECT COUNT(*) AS count
                  FROM ]] .. self.tableName .. [[ AS kill
                  LEFT JOIN ddd_round_roles AS victim_roles 
                  ON kill.round_id == victim_roles.round_id
                  AND kill.victim_id == victim_roles.player_id
                  LEFT JOIN ddd_round_roles AS attacker_roles
                  ON kill.round_id == attacker_roles.round_id
                  AND kill.attacker_id == attacker_roles.player_id
                  WHERE kill.attacker_id == ]] .. tostring(playerId) .. [[
                  AND kill.victim_id != ]] .. tostring(playerId) .. [[
                  AND attacker_roles.role_id == ]] .. tostring(playerRole) .. [[
                  AND victim_roles.role_id == ]] .. tostring(victimRole)
                  
  local result = sql.Query(query)
  return countResult("getRoleKills", result)
end

function playerKillTable:getRoleDeaths(playerId, playerRole, attackerRole)
  local query = [[SELECT COUNT(*) AS count
                  FROM ]] .. self.tableName .. [[ AS kill
                  LEFT JOIN ddd_round_roles AS victim_roles 
                  ON kill.round_id == victim_roles.round_id
                  AND kill.victim_id == victim_roles.player_id
                  LEFT JOIN ddd_round_roles AS attacker_roles
                  ON kill.round_id == attacker_roles.round_id
                  AND kill.attacker_id == attacker_roles.player_id
                  WHERE kill.victim_id == ]] .. tostring(playerId) .. [[
                  AND attacker_roles.role_id == ]] .. tostring(attackerRole) .. [[
                  AND victim_roles.role_id == ]] .. tostring(playerRole)
                  
  local result = sql.Query(query)
  return countResult("getRoleDeaths", result)
end

function playerKillTable:getRoleKillsWithWeapon(playerId, playerRole, victimRole, weaponId)
  local query = [[SELECT COUNT(*) AS count
                  FROM ]] .. self.tableName .. [[ AS kill
                  LEFT JOIN ddd_round_roles AS victim_roles 
                  ON kill.round_id == victim_roles.round_id
                  AND kill.victim_id == victim_roles.player_id
                  LEFT JOIN ddd_round_roles AS attacker_roles
                  ON kill.round_id == attacker_roles.round_id
                  AND kill.attacker_id == attacker_roles.player_id
                  WHERE kill.attacker_id == ]] .. tostring(playerId) .. [[
                  AND kill.victim_id != ]] .. tostring(playerId) .. [[
                  AND attacker_roles.role_id == ]] .. tostring(playerRole) .. [[
                  AND victim_roles.role_id == ]] .. tostring(victimRole) .. [[
                  AND kill.weapon_id == ]] .. tostring(weaponId)
                  
  local result = sql.Query(query)
  return countResult("getRoleKillsWithWeapon", result)
end

function playerKillTable:getRoleDeathsWithWeapon(playerId, playerRole, attackerRole, weaponId)
  local query = [[SELECT COUNT(*) AS count
                  FROM ]] .. self.tableName .. [[ AS kill
                  LEFT JOIN ddd_round_roles AS victim_roles 
                  ON kill.round_id == victim_roles.round_id
                  AND kill.victim_id == victim_roles.player_id
                  LEFT JOIN ddd_round_roles AS attacker_roles
                  ON kill.round_id == attacker_roles.round_id
                  AND kill.attacker_id == attacker_roles.player_id
                  WHERE kill.victim_id == ]] .. tostring(playerId) .. [[
                  AND attacker_roles.role_id == ]] .. tostring(attackerRole) .. [[
                  AND victim_roles.role_id == ]] .. tostring(playerRole) .. [[
                  AND kill.weapon_id == ]] .. tostring(weaponId)
                  
  local result = sql.Query(query)
  return countResult("getRoleDeathsWithWeapon", result)
end

--
-- Kill Selectors
-- Format: Get (Player Class) (Attacker Class) Deaths
--

function playerKillTable:getTraitorInnocentKills(playerId)
  return playerKillTable:getRoleKills(playerId, roles["Traitor"], roles["Innocent"])
end

function playerKillTable:getTraitorDetectiveKills(playerId)
  return playerKillTable:getRoleKills(playerId, roles["Traitor"], roles["Detective"])
end

function playerKillTable:getTraitorTraitorKills(playerId)
  return playerKillTable:getRoleKills(playerId, roles["Traitor"], roles["Traitor"])
end

function playerKillTable:getTraitorTraitorKillsMinusSuicides(playerId)
  return playerKillTable:getRoleKillsMinusSuicides(playerId, roles["Traitor"], roles["Traitor"])
end

function playerKillTable:getInnocentTraitorKills(playerId)
  return playerKillTable:getRoleKills(playerId, roles["Innocent"], roles["Traitor"])
end

function playerKillTable:getInnocentInnocentKills(playerId)
  return playerKillTable:getRoleKills(playerId, roles["Innocent"], roles["Innocent"])
end

function playerKillTable:getInnocentInnocentKillsMinusSuicides(playerId)
  return playerKillTable:getRoleKillsMinusSuicides(playerId, roles["Innocent"], roles["Innocent"])
end

function playerKillTable:getInnocentDetectiveKills(playerId)
  return playerKillTable:getRoleKills(playerId, roles["Innocent"], roles["Detective"])
end

function playerKillTable:getDetectiveTraitorKills(playerId)
  return playerKillTable:getRoleKills(playerId, roles["Detective"], roles["Traitor"])
end

function playerKillTable:getDetectiveInnocentKills(playerId)
  return playerKillTable:getRoleKills(playerId, roles["Detective"], roles["Innocent"])
end

function playerKillTable:getDetectiveDetectiveKills(playerId)
  return playerKillTable:getRoleKills(playerId, roles["Detective"], roles["Detective"])
end

--
-- Death Selectors
-- Format: Get (Player Class) (Attacker Class) Deaths
--

function playerKillTable:getTraitorInnocentDeaths(playerId)
  return playerKillTable:getRoleDeaths(playerId, roles["Traitor"], roles["Innocent"])
end

function playerKillTable:getTraitorDetectiveDeaths(playerId)
  return playerKillTable:getRoleDeaths(playerId, roles["Traitor"], roles["Detective"])
end

function playerKillTable:getTraitorTraitorDeaths(playerId)
  return playerKillTable:getRoleDeaths(playerId, roles["Traitor"], roles["Traitor"])
end

function playerKillTable:getInnocentTraitorDeaths(playerId)
  return playerKillTable:getRoleDeaths(playerId, roles["Innocent"], roles["Traitor"])
end

function playerKillTable:getInnocentInnocentDeaths(playerId)
  return playerKillTable:getRoleDeaths(playerId, roles["Innocent"], roles["Innocent"])
end

function playerKillTable:getInnocentDetectiveDeaths(playerId)
  return playerKillTable:getRoleDeaths(playerId, roles["Innocent"], roles["Detective"])
end

function playerKillTable:getDetectiveTraitorDeaths(playerId)
  return playerKillTable:getRoleDeaths(playerId, roles["Detective"], roles["Traitor"])
end

function playerKillTable:getDetectiveInnocentDeaths(playerId)
  return playerKillTable:getRoleDeaths(playerId, roles["Detective"], roles["Innocent"])
end

function playerKillTable:getDetectiveDetectiveDeaths(playerId)
  return playerKillTable:getRoleDeaths(playerId, roles["Detective"], roles["Detective"])
end

DDD.Database.Tables.PlayerKill = playerKillTable
playerKillTable:create()