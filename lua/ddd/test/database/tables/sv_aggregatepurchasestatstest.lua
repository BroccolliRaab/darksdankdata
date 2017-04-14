local aggregatePurchaseStatsTest = GUnit.Test:new("AggregatePurchaseStatsTable")
local tables = {}

local function beforeEach()
  tables = DDDTest.Helpers.makeTables()
  tables.AggregatePurchaseStats.tables = tables
  tables.MapId:addMap()
end

local function afterEach()
  DDDTest.Helpers.dropAll(tables)
  DDD.Logging:enable()
end

local function allColumnsZero(row)
  for columnName, value in pairs(row) do
    if (columnName != "player_id") then
      GUnit.assert(value):shouldEqual("0")
    end
  end
end

local function confirmRecalculatedValuesMatchOriginal(tables, playerList)
  local oldRows = {}

  for i = 1, #playerList do
    table.insert(oldRows, tables.AggregatePurchaseStats:getPlayerStats(i))
  end

  tables.AggregatePurchaseStats:recalculate()

  for i = 1, #playerList do
    local newRow = tables.AggregatePurchaseStats:getPlayerStats(i)

    for columnName, columnValue in pairs(newRow) do
      GUnit.assert(oldRows[i][columnName]):shouldEqual(columnValue)
    end
  end
end

local function incrementSpec()
  local ply, id = DDDTest.Helpers.genAndAddPlayer(tables)
  local traitorItemNames = DDDTest.Helpers.getTraitorPurchasableItemNames()
  local detectiveItemNames = DDDTest.Helpers.getDetectivePurchasableItemNames()

  tables.AggregatePurchaseStats:addPlayer(id)

  for i = 1, 100 do
    local playerRole = math.random(1, 2)
    local randomItemName

    if (playerRole == ROLE_TRAITOR) then
      local index = math.random(1, #traitorItemNames)
      randomItemName = traitorItemNames[index]
    elseif (playerRole == ROLE_DETECTIVE) then
      local index = math.random(1, #detectiveItemNames)
      randomItemName = detectiveItemNames[index]
    else
      assert(false, "Somehow got an inno role.")
    end

    local originalValue = tables.AggregatePurchaseStats:getPurchases(id, playerRole, randomItemName)
    tables.AggregatePurchaseStats:incrementPurchases(id, playerRole, randomItemName)
    local newValue = tables.AggregatePurchaseStats:getPurchases(id, playerRole, randomItemName)
    GUnit.assert(newValue):shouldEqual(originalValue + 1)
  end
end

local function recalculateSpec()
  local traitorItemNames = DDDTest.Helpers.getTraitorPurchasableItemNames()
  local detectiveItemNames = DDDTest.Helpers.getDetectivePurchasableItemNames()
  local fakePlayerList = DDDTest.Helpers.Generators.makePlayerIdList(tables, 2, 10)

  for index, fakePlayer in pairs(fakePlayerList) do
    tables.AggregatePurchaseStats:addPlayer(fakePlayer.tableId)
  end

  for i = 1, 100 do
    local ply = fakePlayerList[math.random(1, #fakePlayerList)]
    local id = ply.tableId
    local playerRole = math.random(1, 2)
    local randomItemName

    ply:SetRole(playerRole)
    tables.RoundId:addRound()
    tables.RoundRoles:addRole(ply)

    if (playerRole == ROLE_TRAITOR) then
      local index = math.random(1, #traitorItemNames)
      randomItemName = traitorItemNames[index]
    else
      local index = math.random(1, #detectiveItemNames)
      randomItemName = detectiveItemNames[index]
    end

    local itemId = tables.ShopItem:getOrAddItemId(randomItemName)
    tables.AggregatePurchaseStats:incrementPurchases(id, playerRole, randomItemName)
    tables.Purchases:addPurchase(id, itemId)
  end

  confirmRecalculatedValuesMatchOriginal(tables, fakePlayerList) --Need to make fakeplayerlist
end

--[[
Body armor, disguisers, and radars are phantom items. They don't actually go
into your inventory. In essence, they are flags set on your character.
This means they aren't pulled in via an SWEP list, so these specs
are to ensure they are being pulled in in some way.
]]
local function bodyArmorColumnSpec()
  local hasTraitorColumn = false --We don't care about Detectives as much since they always spawn with it

  for key, value in pairs(tables.AggregatePurchaseStats.columns) do
    if (key == "traitor_item_armor_purchases" ) then
      hasTraitorColumn = true
      break
    end
  end

  GUnit.assert(hasTraitorColumn):isTrue()
end

local function disguiserColumnSpec()
  local hasTraitorColumn = false --We don't care about Detectives as much since they always spawn with it

  for key, value in pairs(tables.AggregatePurchaseStats.columns) do
    if (key == "traitor_item_disg_purchases" ) then
      hasTraitorColumn = true
      break
    end
  end

  GUnit.assert(hasTraitorColumn):isTrue()
end

local function radarColumnSpec()
  local hasTraitorColumn = false --We don't care about Detectives as much since they always spawn with it
  local hasDetectiveColumn = false
  for key, value in pairs(tables.AggregatePurchaseStats.columns) do
    if (key == "traitor_item_armor_purchases") then
      hasTraitorColumn = true
    elseif (key == "traitor_item_radar_purchases") then
      hasDetectiveColumn = true
    end
    if (hasTraitorColumn && hasDetectiveColumn) then break end
  end

  GUnit.assert(hasTraitorColumn):isTrue()
  GUnit.assert(hasDetectiveColumn):isTrue()
end

aggregatePurchaseStatsTest:beforeEach(beforeEach)
aggregatePurchaseStatsTest:afterEach(afterEach)
aggregatePurchaseStatsTest:addSpec("increment items purchased", incrementSpec)
aggregatePurchaseStatsTest:addSpec("recalculate properly", recalculateSpec)
aggregatePurchaseStatsTest:addSpec("contain a column for body armor for traitors at least", bodyArmorColumnSpec)
aggregatePurchaseStatsTest:addSpec("contain a column for the disguiser for traitors at least", disguiserColumnSpec)
aggregatePurchaseStatsTest:addSpec("contain a column for a radar for both non-inno roles", radarColumnSpec)