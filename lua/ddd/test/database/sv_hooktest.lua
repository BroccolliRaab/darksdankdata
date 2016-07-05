local hookTest = GUnit.Test:new("DatabaseHooks")
local shopItemGen = DDDTest.Helpers.Generators.ShopItemGen
local tables = {}

local traitorValidPurchases = { "1",
                                "2",
                                "weapon_ttt_flaregun",
                                "weapon_ttt_knife",
                                "weapon_ttt_teleport",
                                "weapon_ttt_radio",
                                "weapon_ttt_push",
                                "weapon_ttt_sipistol",
                                "weapon_ttt_decoy",
                                "weapon_ttt_phammer",
                                "weapon_ttt_c4"}
                              
  local detectiveValidPurchases = { "2", --Forget the body armor since you start with it
                                "weapon_ttt_cse",
                                "weapon_ttt_defuser",
                                "weapon_ttt_teleport",
                                "weapon_ttt_binoculars",
                                "weapon_ttt_stungun",
                                "weapon_ttt_health_station"}
                              
local function beforeEach()
  tables = DDDTest.Helpers.makeTables()
  tables.MapId:addMap()
end

local function afterEach()
  DDDTest.Helpers.dropAll(tables)
end

local function trackPurchasesSpec()
  for i = 1, 100 do
    tables.RoundId:addRound()
    local player = GUnit.Generators.FakePlayer:new()
    local playerId = tables.PlayerId:addPlayer(player)
    tables.AggregateStats:addPlayer(playerId)
    
    local purchaserRole = math.random(1, 2)
    player:SetRole(purchaserRole)
    tables.RoundRoles:addRole(player)
    
    local thisRoundsPurchase
    if purchaserRole == 1 then
      thisRoundsPurchase = traitorValidPurchases[math.random(1, #traitorValidPurchases)]
    else
      thisRoundsPurchase = detectiveValidPurchases[math.random(1, #detectiveValidPurchases)]
    end
    
    local purchaseId = DDD.Hooks.trackPurchases(tables, player, thisRoundsPurchase)
    
    GUnit.assert(purchaseId):shouldEqual(i)
    
    local totalPurchases = tables.AggregateStats:getItemPurchases(playerId, purchaserRole, thisRoundsPurchase)
    if (totalPurchases != 1) then
      print(thisRoundsPurchase)
    end
    
    GUnit.assert(totalPurchases):shouldEqual(1)
  end
end

local function trackDnaDiscoverySpec()
  for i = 1, 100 do
    tables.RoundId:addRound()
    
    local finder = GUnit.Generators.FakePlayer:new()
    local owner = GUnit.Generators.FakePlayer:new()
    tables.PlayerId:addPlayer(finder)
    tables.PlayerId:addPlayer(owner)
    
    local entity = GUnit.Generators.FakeEntity:new()
    
    local id = DDD.Hooks.trackDnaDiscovery(tables, finder, owner, entity)
    GUnit.assert(id):shouldEqual(i)
  end
end

local function trackPlayerCombatDeathSpec()
  for i = 1, 100 do
    local roundId = tables.RoundId:addRound()
    
    local victim = GUnit.Generators.FakePlayer:new()
    local attacker = GUnit.Generators.FakePlayer:new()
    local victimId = tables.PlayerId:addPlayer(victim)
    local attackerId = tables.PlayerId:addPlayer(attacker)
    local weapon = GUnit.Generators.FakeEntity:new()
    local damageInfo = GUnit.Generators.CTakeDamageInfo:new()
    damageInfo:SetInflictor(weapon)
    
    local id = DDD.Hooks.trackPlayerDeath(tables, victim, attacker, damageInfo)
    GUnit.assert(id):shouldEqual(i)
    
    local killRow = tables.PlayerKill:selectById(id)
    GUnit.assert(killRow):shouldNotEqual(0)
    GUnit.assert(tonumber(killRow["round_id"])):shouldEqual(roundId)
    GUnit.assert(tonumber(killRow["victim_id"])):shouldEqual(victimId)
    GUnit.assert(tonumber(killRow["attacker_id"])):shouldEqual(attackerId)
  end
end

local function trackPlayerPushDeathSpec()
  for i = 1, 100 do
    local roundId = tables.RoundId:addRound()
    
    local victim = GUnit.Generators.FakePlayer:new()
    local attacker = GUnit.Generators.FakePlayer:new()
    local victimId = tables.PlayerId:addPlayer(victim)
    local attackerId = tables.PlayerId:addPlayer(attacker)
    local weapon = GUnit.Generators.FakeEntity:new()
    local damageInfo = GUnit.Generators.CTakeDamageInfo:new()
    damageInfo:SetDamageType(DMG_FALL)
    
    local wasPushed = {
      att = attacker,
      wep = weapon:GetClass()
    }
    victim.was_pushed = wasPushed
    
    local id = DDD.Hooks.trackPlayerDeath(tables, victim, nil, damageInfo)
    GUnit.assert(id):shouldEqual(i)
    
    local killRow = tables.PlayerPushKill:selectById(id)
    GUnit.assert(killRow):shouldNotEqual(0)
    GUnit.assert(tonumber(killRow["round_id"])):shouldEqual(roundId)
    GUnit.assert(tonumber(killRow["victim_id"])):shouldEqual(victimId)
    GUnit.assert(tonumber(killRow["attacker_id"])):shouldEqual(attackerId)
  end
end

local function trackPlayerWorldDeathSpec()  
  for i = 1, 100 do
    local roundId = tables.RoundId:addRound()
    
    local victim = GUnit.Generators.FakePlayer:new()
    local victimId = tables.PlayerId:addPlayer(victim)
    local damageInfo = GUnit.Generators.CTakeDamageInfo:new()
    
    local id = DDD.Hooks.trackPlayerDeath(tables, victim, nil, damageInfo)
    GUnit.assert(id):shouldEqual(i)
    
    local killRow = tables.WorldKill:selectById(id)
    GUnit.assert(killRow):shouldNotEqual(0)
    GUnit.assert(tonumber(killRow["round_id"])):shouldEqual(roundId)
    GUnit.assert(tonumber(killRow["victim_id"])):shouldEqual(victimId)
  end
end

local function trackPlayerCombatDamageSpec()
  for i = 1, 100 do
    local roundId = tables.RoundId:addRound()
    
    local victim = GUnit.Generators.FakePlayer:new()
    local attacker = GUnit.Generators.FakePlayer:new()
    local victimId = tables.PlayerId:addPlayer(victim)
    local attackerId = tables.PlayerId:addPlayer(attacker)
    local weapon = GUnit.Generators.FakeEntity:new()
    local damageInfo = GUnit.Generators.CTakeDamageInfo:new()
    damageInfo:SetAttacker(attacker)
    damageInfo:SetInflictor(weapon)
    
    local id = DDD.Hooks.trackDamage(tables, victim, damageInfo)
    GUnit.assert(id):shouldEqual(i)
    
    local damageRow = tables.CombatDamage:selectById(id)
    GUnit.assert(damageRow):shouldNotEqual(0)
    GUnit.assert(tonumber(damageRow["round_id"])):shouldEqual(roundId)
    GUnit.assert(tonumber(damageRow["victim_id"])):shouldEqual(victimId)
    GUnit.assert(tonumber(damageRow["attacker_id"])):shouldEqual(attackerId)
    GUnit.assert(tonumber(damageRow["damage_dealt"])):shouldEqual(damageInfo:GetDamage())
  end
end

local function trackPlayerWorldDamageSpec()
  for i = 1, 100 do
    local roundId = tables.RoundId:addRound()
    
    local victim = GUnit.Generators.FakePlayer:new()
    local victimId = tables.PlayerId:addPlayer(victim)
    local damageInfo = GUnit.Generators.CTakeDamageInfo:new()
    local id = DDD.Hooks.trackDamage(tables, victim, damageInfo)
    GUnit.assert(id):shouldEqual(i)
    
    local damageRow = tables.WorldDamage:selectById(id)
    GUnit.assert(damageRow):shouldNotEqual(0)
    GUnit.assert(tonumber(damageRow["round_id"])):shouldEqual(roundId)
    GUnit.assert(tonumber(damageRow["victim_id"])):shouldEqual(victimId)
    GUnit.assert(tonumber(damageRow["damage_dealt"])):shouldEqual(damageInfo:GetDamage())
  end
end

hookTest:beforeEach(beforeEach)
hookTest:afterEach(afterEach)

hookTest:addSpec("track player purchases", trackPurchasesSpec)
hookTest:addSpec("track when player DNA is found", trackDnaDiscoverySpec)
hookTest:addSpec("track when a player dies from an attacker", trackPlayerCombatDeathSpec)
hookTest:addSpec("track when a player dies from pushing", trackPlayerPushDeathSpec)
hookTest:addSpec("track when a player dies from the world", trackPlayerWorldDeathSpec)
hookTest:addSpec("track when a player takes damage in combat", trackPlayerCombatDamageSpec)
hookTest:addSpec("track when a player takes damage from the world", trackPlayerWorldDamageSpec)