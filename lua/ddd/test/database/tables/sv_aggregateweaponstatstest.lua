local aggregateWeaponStatsTest = GUnit.Test:new("AggregateWeaponStatsTable")
local tables = {}

local function beforeEach()
  tables = DDDTest.Helpers.makeTables()
  tables.AggregateStats.tables = tables
  tables.AggregateWeaponStats.tables = tables
  tables.MapId:addMap()
  --tables.WeaponId:getOrAddWeaponId("ttt_c4")
end

local function afterEach()
  DDDTest.Helpers.dropAll(tables)
  DDD.Logging:enable()
end

local function addWeaponColumnsTest()
  local columns = { player_id = "INTEGER NOT NULL" }
  local weapons = weapons.GetList()

  for key, value in pairs(weapons) do
    if (value.ClassName) then
      columns[value.ClassName] = "INTEGER NOT NULL DEFAULT 0"
    end
  end

  PrintTable(columns)
end

local function addWeaponsToTableSpec()
end

local function recalculateWeaponKillsSpec()
  local oldRows = {}
  local fakePlayerList = DDDTest.Helpers.Generators.makePlayerIdList(tables, 2, 10)
  local weaponList = weapons.GetList()
  local weaponSqlIds = {}

  for index, fakePlayer in pairs(fakePlayerList) do
    tables.AggregateWeaponStats:addPlayer(fakePlayer.tableId)
  end

  for index, weaponInfo in pairs(weaponList) do
    if (weaponInfo.ClassName) then
      local weaponId = tables.WeaponId:addWeapon(weaponInfo.ClassName)
      weaponSqlIds[weaponId] = weaponInfo.ClassName
    end
  end

  local attacker = fakePlayerList[1]
  GUnit.assert(attacker.tableId):shouldEqual(1)


  for i = 1, 100 do
    local victim = fakePlayerList[math.random(2, #fakePlayerList)]
    local weaponId = math.random(1, #weaponSqlIds)

    tables.RoundId:addRound()
    tables.RoundRoles:addRole(attacker)
    tables.RoundRoles:addRole(victim)

    tables.PlayerKill:addKill(victim.tableId, attacker.tableId, weaponId)
    tables.AggregateWeaponStats:incrementKillColumn(weaponSqlIds[weaponId], attacker.tableId, attacker:GetRole(), victim:GetRole())
    tables.AggregateWeaponStats:incrementDeathColumn(weaponSqlIds[weaponId], victim.tableId, attacker:GetRole(), victim:GetRole())
  end

  for i = 1, #fakePlayerList do
    table.insert(oldRows, tables.AggregateWeaponStats:getPlayerStats(i))
  end

  tables.AggregateWeaponStats:recalculate()

  local newRow = tables.AggregateWeaponStats:getPlayerStats(1)

  --Needs to only check kills
  for columnName, columnValue in pairs(newRow) do
    GUnit.assert(oldRows[1][columnName]):shouldEqual(columnValue)
  end
end

aggregateWeaponStatsTest:beforeEach(beforeEach)
aggregateWeaponStatsTest:afterEach(afterEach)

--aggregateWeaponStatsTest:addSpec("add columns based on available SWEPs", addWeaponColumnsTest)
aggregateWeaponStatsTest:addSpec("recalculate every player's kills from the raw data", recalculateWeaponKillsSpec)
