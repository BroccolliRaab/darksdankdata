local tables = DDD.Database.Tables
local roles = DDD.Database.Roles

local columns = { id = "INTEGER PRIMARY KEY",
                  round_id = "INTEGER NOT NULL",
                  finder_id = "INTEGER NOT NULL",
                  corpse_owner_id = "INTEGER NOT NULL",
                  round_time = "REAL NOT NULL"
                }
                
local foreignKeyTable = DDD.Database.ForeignKeyTable:new()
foreignKeyTable:addConstraint("round_id", tables.RoundId, "id")
foreignKeyTable:addConstraint("finder_id", tables.PlayerId, "id")
foreignKeyTable:addConstraint("corpse_owner_id", tables.PlayerId, "id")
              
local corpseIdentifiedTable = DDD.SqlTable:new("ddd_corpse_identified", columns, foreignKeyTable)

function corpseIdentifiedTable:addCorpseFound(finder, corpseOwner, rag)
  local playerIdTable = self:getForeignTableByColumn("finder_id")
  local ownerId
  
  if (corpseOwner) then
    ownerId = corpseOwner:SteamID()
  else
    ownerId = CORPSE.GetPlayerSteamID(rag, "")
  end
  
  local insertTable = {
    round_id = self:getForeignTableByColumn("round_id"):getCurrentRoundId(),
    finder_id = playerIdTable:getPlayerId(finder),
    corpse_owner_id = playerIdTable:getPlayerIdBySteamId(ownerId),
    round_time = DDD.CurrentRound:getCurrentRoundTime()
  }
  return self:insertTable(insertTable)
end

corpseIdentifiedTable:create()
DDD.Database.Tables.CorpseIdentified = corpseIdentifiedTable