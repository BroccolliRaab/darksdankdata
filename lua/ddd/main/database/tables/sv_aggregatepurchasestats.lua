local itemColumnSuffix = {}
local tables = DDD.Database.Tables

local function roleCanBuy(swep, role)
  if (!swep.CanBuy) then
    return false
  end

  for index, roleId in pairs(swep.CanBuy) do
    if (roleId == role) then
      return true
    end
  end

  return false
end

local function traitorCanBuy(swep)
  return roleCanBuy(swep, ROLE_TRAITOR)
end

local function detectiveCanBuy(swep)
  return roleCanBuy(swep, ROLE_DETECTIVE)
end

local function generateColumns()
  local columns = {
    player_id = "INTEGER PRIMARY KEY"
  }
  local sweps = weapons.GetList()

  for index, wep in pairs(sweps) do

    if traitorCanBuy(wep) then
      local columnName = "traitor_" .. wep.ClassName .. "_purchases"
      columns[columnName] = "INTEGER NOT NULL DEFAULT 0"
    end

    if detectiveCanBuy(wep) then
      local columnName = "detective_" .. wep.ClassName .. "_purchases"
      columns[columnName] = "INTEGER NOT NULL DEFAULT 0"
    end

  end

  return columns
end

local columns = generateColumns()

local foreignKeyTable = DDD.Database.ForeignKeyTable:new()
foreignKeyTable:addConstraint("player_id", tables.PlayerId, "id")

local aggregatePurchaseStatsTable = DDD.SqlTable:new("ddd_aggregate_purchase_stats", columns, foreignKeyTable)
aggregatePurchaseStatsTable.tables = tables --So they can be easily swapped out in test

function aggregatePurchaseStatsTable:addPlayer(playerId)
  local newPlayerTable = {
    player_id = playerId
  }
  return self:insertTable(newPlayerTable)
end

function aggregatePurchaseStatsTable:getPlayerStats(playerId)
  local query = "SELECT * from " .. self.tableName .. " WHERE player_id == " .. playerId
  return self:query("aggregatePurchaseStatsTable:getPlayerStats", query, 1)
end

function aggregatePurchaseStatsTable:getPurchases(playerId, playerRole, itemName)
  local columnName = DDD.roleIdToRole[playerRole] .. "_" .. itemName .. "_purchases"
  local query = "SELECT " .. columnName .. " FROM " .. self.tableName .. " WHERE player_id == " .. playerId
  local currentValue = self:query("aggregatePurchaseStatsTable:selectColumn", query, 1, columnName)
  return tonumber(currentValue)
end

function aggregatePurchaseStatsTable:incrementPurchases(playerId, playerRole, itemName)
    assert(playerRole != 0, "Innocents can't purchase items!")
    local newPurchases = self:getPurchases(playerId, playerRole, itemName) + 1
    local columnName = DDD.roleIdToRole[playerRole] .. "_" .. itemName .. "_purchases"
    local query = "UPDATE " .. self.tableName .. " SET " .. columnName .. " = " .. newPurchases .. " WHERE player_id == " .. playerId
    return self:query("aggregatePurchaseStatsTable:incrementPurchases", query)
end

function aggregatePurchaseStatsTable:recalculate()
  local query = [[SELECT purchases.player_id, roundroles.role_id, purchases.shop_item_id, shopitem.name, count(purchases.shop_item_id) AS times_purchased
                  FROM ]] .. self.tables.Purchases.tableName .. [[ AS purchases
                  LEFT JOIN ]] .. self.tables.ShopItem.tableName .. [[ AS shopitem ON purchases.shop_item_id = shopitem.id,
                   ]] .. self.tables.RoundRoles.tableName .. [[ AS roundroles ON purchases.round_id = roundroles.round_id AND purchases.player_id = roundroles.player_id
                  GROUP BY purchases.player_id, shop_item_id, roundroles.role_id
                  ORDER BY purchases.player_id, roundroles.role_id]]

  local result = self:query("aggregatePurchaseStatsTable:recalculate", query)

  local rowsToInsert = {}

  for index, row in pairs(result) do
    local playerId = row["player_id"]

    if rowsToInsert[playerId] == nil then
      rowsToInsert[playerId] = {}
    end

    local columnName = ""

    if tonumber(row["role_id"]) == ROLE_TRAITOR then
      columnName = "traitor_" .. row["name"] .. "_purchases"
    else
      columnName = "detective_" .. row["name"] .. "_purchases"
    end

    rowsToInsert[playerId][columnName] = row["times_purchased"]
  end

  for playerId, columns in pairs(rowsToInsert) do
    local numColumns = 0
    local timesIterated = 0
    local columnList = " ("
    local valueList = " ("

    for column, value in pairs(columns) do
      numColumns = numColumns + 1
    end

    for column, value in pairs(columns) do
      timesIterated = timesIterated + 1
      columnList = columnList .. column
      valueList = valueList .. value
      if timesIterated < numColumns then
        columnList = columnList .. ", "
        valueList = valueList .. ", "
      end
    end

    columnList = columnList .. ")"
    valueList = valueList .. ")"

    local insertQuery = "INSERT INTO " .. self.tableName .. columnList .. " VALUES " .. valueList
    self:query("aggregatePurchaseStatsTable:recalculate insert step", insertQuery)
  end
end

aggregatePurchaseStatsTable.traitorCanBuy = traitorCanBuy
aggregatePurchaseStatsTable.detectiveCanBuy = detectiveCanBuy

aggregatePurchaseStatsTable:create()
DDD.Database.Tables.AggregatePurchaseStats = aggregatePurchaseStatsTable
