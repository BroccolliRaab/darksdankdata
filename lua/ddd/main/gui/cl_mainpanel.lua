local function configureMainPanel(mainFrame)
  mainFrame:SetPos(0, 0)
  mainFrame:SetSize(640, 480)
  mainFrame:SetTitle("Dark's Dank Data")
  mainFrame:SetDraggable(true)
  mainFrame:Center()
end

--Creates and adds the main Property Sheet (tabbed window that lives inside the panel) to the mainFrame
local function addStatsPropertySheet(mainPropertySheet)
  net.Start("DDDGetStats")
  net.SendToServer()
  net.Receive("DDDGetStats", function(len, _)
      local traitorItemNames = net.ReadTable()
      local detectiveItemNames = net.ReadTable()
      local statsTable = net.ReadTable()
      local statsPropertySheet = vgui.Create("DPropertySheet", mainPropertySheet)

      statsPropertySheet:Dock(FILL)
      DDD.Gui.setSizeToParent(statsPropertySheet)
      DDD.Gui.createOverviewTab(statsPropertySheet, statsTable)
      DDD.Gui.createTraitorTab(statsPropertySheet, statsTable, traitorItemNames)
      DDD.Gui.createInnocentTab(statsPropertySheet, statsTable)
      DDD.Gui.createDetectiveTab(statsPropertySheet, statsTable, detectiveItemNames)
      mainPropertySheet:AddSheet("Stats", statsPropertySheet, "icon16/chart_bar.png")
    end)
end

local function addRankPropertySheet(mainPropertySheet)
  net.Start("DDDGetRankings")
  net.SendToServer()
  net.Receive("DDDGetRankings", function(len, _)
    local rankTable = net.ReadTable()
    local rankPropertySheet = vgui.Create("DPropertySheet", mainPropertySheet)

    DDD.Gui.Rank.createOverallTab(rankPropertySheet, rankTable)
    DDD.Gui.Rank.createDetectiveTab(rankPropertySheet, rankTable)
    DDD.Gui.Rank.createInnocentTab(rankPropertySheet, rankTable)
    DDD.Gui.Rank.createTraitorTab(rankPropertySheet, rankTable)
    rankPropertySheet:Dock(FILL)
    DDD.Gui.setSizeToParent(rankPropertySheet)
    mainPropertySheet:AddSheet("Rank", rankPropertySheet, "icon16/chart_bar.png")
  end)
end

function DDD.createMainFrame()
  local mainFrame = vgui.Create( "DFrame" )
  local mainPropertySheet = vgui.Create( "DPropertySheet", mainFrame )
  mainPropertySheet:Dock(FILL)
  configureMainPanel(mainFrame)
  addRankPropertySheet(mainPropertySheet)
  addStatsPropertySheet(mainPropertySheet)
  mainFrame:MakePopup()
end
