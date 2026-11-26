-- Public standalone entry; rerunning replaces the previous hub.
local STATE: any = nil
-- Anime Brawlers Simulator | Real MCP | Rayfield Gen2
-- Place 117337409758030, observed version 3417.
-- Run through Real. Re-running replaces the previous instance.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
assert(game.PlaceId == 117337409758030, "Este menu foi feito para Anime Brawlers Simulator.")
local env = getgenv()
if env.AnimeBrawlersHub then env.AnimeBrawlersHub.Cleanup() end
local remotes: any = RS:WaitForChild("GameRemotes", 10)
assert(remotes, "GameRemotes indisponivel")
local action = remotes:WaitForChild("Action")
local function module(name)
    local item: any = RS:WaitForChild(name, 10)
    assert(item, "Modulo indisponivel: " .. name)
    return require(item)
end
local config = module("GameConfig")
local range = module("CombatTargetRange")
local policy = module("GachaOpenPolicy")
local quests = module("QuestPresentation")
local reveal = module("GachaRollVisual")
local trialConfig = module("TrialConfig")
local trialState: any = RS:WaitForChild("TrialState", 10)
local trialRemote: any = remotes:WaitForChild("TrialAction", 10)
local snapshot: any = remotes.GetSnapshot:InvokeServer()
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()
local window = Rayfield:CreateWindow({
    name = "Anime Brawlers | Real",
    subtitle = "Autofarm • Estrelas • Missoes",
    sidebarLayout = true,
    theme = "cobalt",
    ToggleUIKeybind = Enum.KeyCode.RightShift,
    configuration = {autoSave = true, autoLoad = true, fileName = "AnimeBrawlersReal_v1"},
})
local hub: any = {Alive = true, Window = window, Controls = {}, Connections = {},
    Status = "Pronto", FarmStatus = "Desligado", AttackStatus = "Desligado", OpenStatus = "Desligado", Opens = 0,
    Started = os.clock(), InitialYen = snapshot.Yen or 0, Errors = 0, TrialStatus = "Desligado"}
env.AnimeBrawlersHub = hub
local options: any = {
    farm = false, autoAttack = false, click = false, cps = 5, mode = "Menor vida", enemy = "Todos",
    bosses = "Todos", approach = true, radius = 750, distance = 7,
    questPriority = true, autoQuest = false, autoEquip = false, autoClaim = false,
    autoOpen = false, star = "Warrior Star", approachStar = true, reserve = 0,
    maxOpens = 0, stopRare = "Nao parar", pauseFull = true, openDelay = 5,
    walk = 20, customWalk = false,
    autoTrial = false, trialLead = 5, trialClick = true,
    autoFuse = false, fuseTarget = nil, fuseRarities = {}, fuseShiny = false,
    fuseBatch = 20, fuseInterval = 5,
}
hub.Options = options
local connections = hub.Connections
local function connect(signal, callback)
    local c = signal:Connect(function(...)
        setthreadidentity(8)
        callback(...)
    end)
    table.insert(connections, c)
    return c
end
local camera = workspace.CurrentCamera
local oldFov = camera and camera.FieldOfView
local oldWalk: {[Instance]: number} = {}
local function send(command, ...)
    if hub.Alive then action:FireServer(command, ...) end
end
local function notify(message)
    setthreadidentity(8)
    if hub.Alive and not window.unloaded then
        window:Notify({title = "Anime Brawlers", content = tostring(message), duration = 4})
    end
end
local function root()
    local c = player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function humanoid()
    local c = player.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function stopMovement()
    local h, r = humanoid(), root()
    if h and r then h:MoveTo(r.Position) end
end
local function stopAll()
    setthreadidentity(8)
    for _, key in ipairs({"farm", "autoAttack", "click", "autoOpen", "autoQuest", "autoEquip", "autoClaim", "autoTrial", "autoFuse"}) do
        options[key] = false
        if hub.Controls[key] then hub.Controls[key]:Set(false, true) end
    end
    if hub.Trial then hub.Trial:Cancel(false) end
    hub.ManualFuse = false
    hub.Target = nil
    hub.FarmStatus, hub.OpenStatus = "Desligado", "Desligado"
    hub.AttackStatus = "Desligado"
    send("Retreat")
    stopMovement()
end
hub.StopAll = stopAll
function hub.Cleanup()
    if not hub.Alive then return end
    stopAll()
    if hub.Trial then hub.Trial:Shutdown() end
    if hub.EndTrialTouch then hub.EndTrialTouch() end
    hub.Alive = false
    for _, c in ipairs(connections) do c:Disconnect() end
    for h, speed in pairs(oldWalk) do if h.Parent then (h :: any).WalkSpeed = speed end end
    if camera and camera.Parent and oldFov then camera.FieldOfView = oldFov end
    if not window.unloaded then window:Unload() end
    if env.AnimeBrawlersHub == hub then env.AnimeBrawlersHub = nil end
end
-- STATE is supplied by Real live-reload; ordinary executor runs use global cleanup above.
if STATE then STATE.onCleanup(hub.Cleanup) end
local function toggle(tab, name, key, description)
    local control = tab:CreateToggle({name = name, description = description,
        value = options[key] == true, flag = "ABR_" .. key, forgetState = true,
        callback = function(value)
            options[key] = value
            if key == "farm" or key == "autoAttack" then
                setthreadidentity(8)
                hub.Target = nil
                if not hub.Trial or not hub.Trial:IsBusy() then send("Retreat"); stopMovement() end
                if value then
                    local other = if key == "farm" then "autoAttack" else "farm"
                    options[other] = false
                    if hub.Controls[other] then hub.Controls[other]:Set(false, true) end
                end
                if not options.farm then hub.FarmStatus = "Desligado" end
                if not options.autoAttack then hub.AttackStatus = "Desligado" end
            end
            if key == "autoOpen" and value then hub.OpenStart = hub.Opens end
            if key == "autoTrial" and not value and hub.Trial then hub.Trial:Cancel(true) end
        end})
    hub.Controls[key] = control
    return control
end
local function slider(tab, name, key, min, max, step)
    local control=tab:CreateSlider({name = name, range = {min, max}, increment = step or 1,
        value = options[key], flag = "ABR_" .. key,
        callback = function(value) options[key] = value end})
    hub.Controls[key]=control
    return control
end
local function dropdown(tab, name, key, values)
    local control=tab:CreateDropdown({name = name, options = values, value = options[key],
        flag = "ABR_" .. key, callback = function(value)
            options[key] = value
            if key == "enemy" or key == "bosses" then hub.Target = nil end
        end})
    hub.Controls[key]=control
    return control
end
local function button(tab, name, callback, description)
    return tab:CreateButton({name = name, callback = callback, description = description})
end
local function nativeSetting(tab, name, key, description)
    return tab:CreateToggle({name = name, description = description,
        value = snapshot.Settings and snapshot.Settings[key] == true, forgetState = true,
        callback = function(v) send("SetSetting", key, v) end})
end
local stars, starNames, worldNames, worldIds = {}, {}, {}, {}
local starParts = {"NamePlanetStarPart", "PlantTownStarPart", "WestwallStarPart", "VacuumWorldStarPart", "DistrictofFunStarPart"}
for wi, w in ipairs(config.Worlds) do
    local label = tostring(wi) .. " - " .. w.Name
    table.insert(worldNames, label)
    worldIds[label] = wi
    for _, g in ipairs(w.Gachas or {}) do
        -- DripStar uses a premium purchase flow, so it is not an auto-open destination.
        if g.Id ~= "DripStar" then
            stars[g.Name] = {world = wi, id = g.Id, cost = g.Cost, map = w.MapName}
            table.insert(starNames, g.Name)
        end
    end
end
local function starPart(star)
    if not star then return nil end
    local cached = star.part
    if cached and cached.Parent then return cached end
    local name = starParts[star.world]
    local v = name and workspace:FindFirstChild(name, true)
    if v and v:IsA("BasePart") then star.part = v; return v end
    return nil
end
local function moveNear(position, teleport)
    local r, h = root(), humanoid()
    if not r or not h or h.Health <= 0 then return false end
    if teleport then
        r.CFrame = CFrame.new(position)
        r.AssemblyLinearVelocity = Vector3.zero
    else
        h:MoveTo(position)
    end
    return true
end
-- BEGIN TRIAL CONTROLLER: pure lifecycle, exercised by tests/trial-controller.spec.luau.
local function createTrialController(io)
    local c: any = {Phase="Idle", Status="Desligado", Context=nil, Data=nil, Result=nil,
        Attempted=nil, NextRequest=0, Requested=false, Resume=true, RunId=nil, Closed=false}
    function c:IsBusy() return self.Phase~="Idle" end
    function c:Request() self.Requested=true end
    function c:OnEvent(kind,payload)
        if not self.Context then return end
        if kind=="State" and type(payload)=="table" then
            if not self.RunId or payload.Id==self.RunId then self.Data=payload end
        elseif kind=="Result" and type(payload)=="table" then
            if not self.RunId or not payload.Id or payload.Id==self.RunId then self.Result=payload end
        elseif kind=="Notice" or kind=="ReturnFailed" then
            io.log("Trial: "..tostring(payload or kind))
        end
    end
    function c:Cancel(resume)
        self.Requested=false
        if not self.Context then return end
        self.Resume=resume==true
        if self.Phase~="Returning" and self.Phase~="Restoring" then
            self.Phase="Returning"; self.Deadline=nil; self.NextRequest=0
            io.pause()
        end
    end
    function c:Shutdown()
        if self.Context then io.exit(self.Context,self.Result~=nil) end
        self.Closed=true
    end
    function c:Step(v)
        if self.Closed then return end
        local now=v.Clock
        local inside=v.Active~=nil or v.InLobby==true
        if self.Phase=="Idle" then
            if not v.Enabled and not self.Requested then self.Status="Desligado";return end
            if v.OtherEvent or v.Loading or v.Dead then self.Status="Aguardando personagem / outro evento";return end
            local last=v.LastStarted
            local recent=last and v.Time>=last and v.Time-last<v.Grace
            local nextAt=v.NextAt
            local due=nextAt and v.Time>=nextAt-v.Lead and v.Time<=nextAt+v.Grace
            local cycle=recent and last or nextAt
            if not inside and not self.Requested and (not (recent or due) or cycle==self.Attempted) then
                self.Status="Proxima trial em "..tostring(math.max(0,math.ceil((nextAt or v.Time)-v.Time))).."s"
                return
            end
            local context=io.capture()
            if not context then self.Status="Aguardando posicao de retorno";return end
            self.Context=context; self.Result=nil; self.Data=nil; self.RunId=v.Active
            self.Attempted=cycle; self.Resume=true; self.Requested=false
            self.Phase=inside and (v.Active and "Running" or "Lobby") or "Joining"
            self.Deadline=now+25; self.NextRequest=0; self.EmptySince=nil
            io.pause();io.log("Trial: farm pausado; retorno salvo na ilha "..tostring(context.World))
        end
        if self.Phase=="Joining" then
            self.Status="Entrando na trial"
            if inside then
                self.Phase=v.Active and "Running" or "Lobby";self.EmptySince=nil
            elseif now>=self.Deadline then
                io.log("Trial: entrada nao confirmada; restaurando farm")
                self.Phase="Returning";self.Deadline=nil;self.NextRequest=0
            elseif now>=self.NextRequest then self.NextRequest=now+5;io.enter() end
        end
        if self.Phase=="Lobby" then
            self.Status="No lobby, aguardando inicio"
            if v.Active then
                self.RunId=v.Active;self.Phase="Running";self.Attempted=v.LastStarted or self.Attempted
                io.log("Trial iniciada: "..tostring(v.Active))
            elseif not inside then
                self.EmptySince=self.EmptySince or now
                if now-self.EmptySince>=2 then self.Phase="Returning";self.Deadline=nil;self.NextRequest=0 end
            else self.EmptySince=nil end
        end
        if self.Phase=="Running" then
            self.RunId=self.RunId or v.Active
            if self.Result or not inside then
                self.Phase="Returning";self.Deadline=nil;self.NextRequest=0
                self.ResultAt=now
                io.pause()
                io.log("Trial encerrada"..(self.Result and (self.Result.Success and ": vitoria" or ": derrota")or ""))
            elseif v.Dead or v.Loading then self.Status="Trial: aguardando personagem"
            else
                local room=v.Room or (self.Data and self.Data.Room) or 0
                self.Status=io.combat(v,self.Data) or ("Trial, sala "..tostring(room))
            end
        end
        if self.Phase=="Returning" then
            self.Status="Voltando ao farm anterior"
            self.Deadline=self.Deadline or now+60
            if not inside and v.World==self.Context.World and not v.Loading then
                self.Phase="Restoring";self.RestoreAt=now+1;self.StableAt=nil;self.NextRequest=0
            elseif now>=self.NextRequest and (not self.ResultAt or now-self.ResultAt>=2) then
                self.NextRequest=now+4;io.exit(self.Context,self.Result~=nil)
            end
            if now>=self.Deadline and self.Phase=="Returning" then
                self.Status="Retorno nao confirmado; farm permanece pausado"
                if not self.ReturnWarning then self.ReturnWarning=true;io.log(self.Status) end
            end
        end
        if self.Phase=="Restoring" then
            self.Status="Restaurando posicao e farm"
            if inside or v.World~=self.Context.World then
                self.Phase="Returning";self.NextRequest=0;self.Deadline=nil;return
            end
            if v.Dead or v.Loading or now<self.RestoreAt then return end
            if io.atOrigin(self.Context) then
                self.StableAt=self.StableAt or now
                if now-self.StableAt>=1 then
                    local context=self.Context
                    self.Context=nil;self.Phase="Idle";self.RunId=nil;self.Data=nil;self.Result=nil
                    self.ReturnWarning=nil;self.ResultAt=nil;self.EmptySince=nil
                    io.resume(context,self.Resume)
                    self.Status=self.Resume and "Farm anterior retomado" or "Parado pelo usuario"
                end
            elseif now>=self.NextRequest then
                self.StableAt=nil;self.NextRequest=now+1;io.restore(self.Context)
            end
        end
    end
    return c
end
-- END TRIAL CONTROLLER

local home = window:CreateTab({name = "Inicio"})
local status = home:CreateText({name = "Sessao ao vivo", text = "Carregando..."})
local activity = home:CreateText({name = "Atividade", text = ""})
local logLines = {}
local log = {}
function log:Append(line)
    setthreadidentity(8)
    table.insert(logLines, tostring(line))
    if #logLines > 12 then table.remove(logLines, 1) end
    activity:Set(table.concat(logLines, "\n"))
end
function log:Get() return table.concat(logLines, "\n") end
hub.Log = log
button(home, "PARAR TODAS AS AUTOMACOES", stopAll)
button(home, "Atualizar dados", function()
    task.spawn(function()
        local ok, data = pcall(function() return remotes.GetSnapshot:InvokeServer() end)
        if ok and hub.Alive then snapshot = data; hub.Snapshot = data; notify("Dados atualizados") end
    end)
end)
home:CreateKeybind({name = "Parada de emergencia", value = Enum.KeyCode.F8, callback = stopAll})
home:CreateKeybind({name = "Mostrar / esconder menu", value = Enum.KeyCode.RightControl,
    callback = function() window:ToggleHide() end})

local farmTab = window:CreateTab({name = "Autofarm"})
toggle(farmTab, "Auto Attack", "autoAttack", "Ataca qualquer inimigo vivo ao alcance, sem mover voce. Troca de alvo apos a derrota; substitui o autofarm.")
toggle(farmTab, "Ativar autofarm", "farm", "Seleciona inimigos vivos da ilha atual e envia seus brawlers.")
toggle(farmTab, "Clique de dano automatico", "click", "Ate 6 cliques/s; funciona com o alvo de combate selecionado.")
slider(farmTab, "Cliques por segundo", "cps", 1, 6)
dropdown(farmTab, "Escolha de alvo", "mode", {"Menor vida", "Mais proximo", "Melhor Yen por vida"})
local enemyDropdown = dropdown(farmTab, "Inimigo especifico", "enemy", {"Todos"})
dropdown(farmTab, "Filtro de chefes", "bosses", {"Todos", "Sem chefes", "Apenas chefes"})
toggle(farmTab, "Aproximar automaticamente", "approach", "Posiciona perto do alvo quando fora do alcance.")
slider(farmTab, "Raio de busca (studs)", "radius", 50, 1500, 25)
slider(farmTab, "Distancia do inimigo", "distance", 5, 30)
toggle(farmTab, "Priorizar objetivos da missao", "questPriority", "Escolhe a categoria que ainda falta na missao atual.")
nativeSetting(farmTab, "Enviar todos os brawlers", "SendAllFighters")
nativeSetting(farmTab, "Desativar retirada ao clicar no alvo", "DisableCursorRetreat")
button(farmTab, "Recuar brawlers", function() hub.Target = nil; send("Retreat") end)
local function refreshEnemies()
    local names, seen = {"Todos"}, {}
    local folder = workspace:FindFirstChild("LiveNPCs")
    if folder then
        for _, n in ipairs(folder:GetChildren()) do
            if n:GetAttribute("WorldIndex") == (player:GetAttribute("CurrentWorld") or 1) and not seen[n.Name] then
                seen[n.Name] = true; table.insert(names, n.Name)
            end
        end
    end
    table.sort(names, function(a, b) if a == "Todos" then return true elseif b == "Todos" then return false else return a < b end end)
    enemyDropdown:Refresh(names)
end
button(farmTab, "Atualizar lista de inimigos", refreshEnemies)
refreshEnemies()

local trialTab = window:CreateTab({name = "Auto Trial"})
toggle(trialTab, "Entrar e fazer trial automaticamente", "autoTrial", "Pausa o farm perto da abertura, combate e avanca nas salas; depois volta a ilha e posicao anteriores.")
slider(trialTab, "Antecedencia para entrar no lobby (s)", "trialLead", 3, 60, 1)
toggle(trialTab, "Cliques de dano durante a trial", "trialClick", "Usa o limite de cliques por segundo da aba Autofarm.")
local trialText = trialTab:CreateText({name = "Trial ao vivo", text = "Desligado"})
button(trialTab, "Entrar no lobby agora", function() if hub.Trial then hub.Trial:Request() end end,
    "Entra imediatamente e aguarda a proxima abertura. O farm fica pausado enquanto estiver no lobby.")
button(trialTab, "Sair da trial e retomar farm", function()
    options.autoTrial=false;hub.Controls.autoTrial:Set(false,true)
    if hub.Trial then hub.Trial:Cancel(true) end
end)
trialTab:CreateText({name = "Retorno automatico", text = "As opcoes do farm e auto open ficam preservadas. Ao terminar ou perder, a automacao confirma a saida, volta a ilha e a posicao salvas e retoma o que estava ligado. F8 cancela a retomada. A vitoria depende do dano da equipe."})

local openTab = window:CreateTab({name = "Auto Open"})
toggle(openTab, "Abrir estrelas automaticamente", "autoOpen", "Aguarda saldo, espaco e o fim da animacao antes da proxima abertura.")
dropdown(openTab, "Estrela", "star", starNames)
toggle(openTab, "Ir ate a estrela", "approachStar", "Mantem o personagem junto a estrela da ilha atual.")
slider(openTab, "Intervalo minimo entre aberturas (s)", "openDelay", 4, 12, 0.5)
slider(openTab, "Reserva de Yen", "reserve", 0, 100000, 100)
slider(openTab, "Limite de brawlers nesta execucao (0 = livre)", "maxOpens", 0, 1000, 1)
dropdown(openTab, "Parar ao obter", "stopRare", {"Nao parar", "Shiny", "Legendary+", "Mythical+", "Secret"})
toggle(openTab, "Pausar com inventario cheio", "pauseFull", "A opcao desligada encerra o auto open quando o inventario enche.")
button(openTab, "Ir para a estrela selecionada", function()
    local s = stars[options.star]
    local p = starPart(s)
    if not s or s.world ~= (player:GetAttribute("CurrentWorld") or 1) then notify("Viaje para a ilha da estrela primeiro."); return end
    if p then moveNear(p.Position + Vector3.new(0, 0, 7), true) else notify("Estrela nao encontrada nesta ilha.") end
end)
button(openTab, "Abrir uma vez", function() hub.ManualOpen = true end)
nativeSetting(openTab, "Ocultar flash das estrelas", "HideStarFlash")

local invTab = window:CreateTab({name = "Brawlers"})
button(invTab, "Equipar melhores agora", function() send("EquipBest") end)
toggle(invTab, "Equipar melhores automaticamente", "autoEquip", "Verifica a equipe a cada 10 segundos.")
button(invTab, "Desequipar todos", function() send("UnequipAll") end)
-- These switches use the game's native policies; they affect future rolls.
for _, rarity in ipairs({"Common", "Rare", "Epic", "Legendary", "Mythical", "Secret"}) do
    invTab:CreateToggle({name = "Travar novos " .. rarity .. " (normal)", forgetState = true,
        value = snapshot.AutoLock and snapshot.AutoLock[rarity] and snapshot.AutoLock[rarity].Normal == true,
        callback = function(v) send("SetFighterAutomation", "AutoLock", {Rarity = rarity, Variant = "Normal"}, v) end})
end
for _, rarity in ipairs({"Common", "Rare", "Epic"}) do
    invTab:CreateToggle({name = "Vender novos " .. rarity .. " (normal)", forgetState = true,
        description = "Vende automaticamente os proximos sorteados desta categoria.",
        value = snapshot.AutoSell and snapshot.AutoSell[rarity] and snapshot.AutoSell[rarity].Normal == true,
        callback = function(v) send("SetFighterAutomation", "AutoSell", {Rarity = rarity, Variant = "Normal"}, v) end})
end
button(invTab, "Travar novos shinies de todas as raridades", function()
    for _, rarity in ipairs({"Common", "Rare", "Epic", "Legendary", "Mythical", "Secret"}) do
        send("SetFighterAutomation", "AutoLock", {Rarity = rarity, Variant = "Shiny"}, true)
    end
    notify("Auto-lock de shinies solicitado.")
end)
local invConsole = invTab:CreateText({name = "Resumo da equipe", text = "Carregando..."})

-- BEGIN AUTO FUSE CONTROLLER
local function createFuseController(adapters)
    local c: any = {Pending = nil, Blocked = false, NextAt = 0, Batches = 0,
        MaterialsUsed = 0, Status = "Desligado", SyncSerial = 0, SyncInFlight = false,
        SyncOK = true, NextSyncAt = 0, RecoveryCount = 0, SyncFailures = 0}
    function c:Plan(v)
        local plan: any = {Target = nil, UIDs = {}, Materials = {}, XP = 0, Eligible = 0,
            Status = "Selecione o boneco que recebera XP"}
        if type(v.Inventory) ~= "table" then plan.Status = "Aguardando inventario"; return plan end
        local seen = {}
        for _, f in ipairs(v.Inventory) do
            if f.UID == v.TargetUID then
                if plan.Target then plan.Target = nil; plan.Status = "ID de destino ambiguo"; return plan end
                plan.Target = f
            end
        end
        if not plan.Target then return plan end
        if (tonumber(plan.Target.Level) or 1) >= v.MaxLevel then
            plan.Status = "Destino no nivel maximo"; plan.Stop = true; return plan
        end
        local rarities = {}
        for _, rarity in ipairs(v.Rarities or {}) do rarities[rarity] = true end
        if next(rarities) == nil then plan.Status = "Selecione as raridades dos materiais"; return plan end
        local limit = math.clamp(math.floor(tonumber(v.BatchSize) or 20), 1, 50)
        for _, f in ipairs(v.Inventory) do
            local xp = tonumber(f.FeedXP) or 0
            if type(f.UID) == "string" and f.UID ~= v.TargetUID and not seen[f.UID]
                and rarities[f.Rarity] and not f.Locked and not f.Equipped and not f.Starter
                and (v.IncludeShiny or not f.Shiny) and xp > 0 then
                seen[f.UID] = true
                plan.Eligible += 1
                if #plan.UIDs < limit then
                    table.insert(plan.UIDs, f.UID)
                    table.insert(plan.Materials, f)
                    plan.XP += xp
                end
            end
        end
        plan.Status = if #plan.UIDs > 0 then "Pronto para fundir" else "Aguardando materiais das raridades escolhidas"
        return plan
    end
    function c:Fail(message)
        self.Blocked = true
        self.Status = message
        adapters.pause(message)
    end
    function c:ResetAfterSync()
        self.SyncSerial += 1
        self.SyncOK = true
        self.RecoveryCount, self.SyncFailures = 0, 0
        if self.Blocked then self.Pending = nil; self.Blocked = false end
    end
    function c:RequestSync(now)
        if self.SyncInFlight or now < self.NextSyncAt then return end
        self.SyncInFlight = true
        self.NextSyncAt = now + 3
        adapters.sync(function(ok)
            self.SyncInFlight = false
            self.SyncSerial += 1
            self.SyncOK = ok == true
        end)
    end
    function c:OnResult(ok, message, data, tag)
        local pending = self.Pending
        if not pending or tag ~= "FighterFeed" then return end
        if type(data) == "table" and data.TargetUID and data.TargetUID ~= pending.TargetUID then return end
        pending.ResultSeen = true
        pending.ResultOK = ok == true
        pending.Message = tostring(message or "Fusao recusada pelo servidor")
    end
    function c:Step(v)
        if self.Pending then
            local present, target = {}, nil
            for _, f in ipairs(v.Inventory or {}) do
                present[f.UID] = true
                if f.UID == self.Pending.TargetUID then target = f end
            end
            if not target then
                if self.SyncSerial > self.Pending.SyncSerial and self.SyncOK then
                    if not self.Blocked then self:Fail("Destino ausente; selecione outro boneco") end
                else self:RequestSync(v.Clock) end
                return
            end
            local remaining = 0
            for _, uid in ipairs(self.Pending.UIDs) do if present[uid] then remaining += 1 end end
            if remaining == 0 then
                self.Batches += 1
                self.MaterialsUsed += #self.Pending.UIDs
                adapters.log("Fuse confirmado: " .. #self.Pending.UIDs .. " materiais -> " .. tostring(target.Name))
                self.Pending = nil
                self.RecoveryCount, self.SyncFailures = 0, 0
            else
                if self.Blocked then return end
                self.Status = "Aguardando confirmacao do servidor"
                if self.SyncSerial > self.Pending.SyncSerial then
                    if self.SyncOK then
                        local removed = #self.Pending.UIDs - remaining
                        if removed > 0 then
                            self.MaterialsUsed += removed
                            adapters.log("Fuse: inventario sincronizado; " .. removed .. " materiais removidos")
                        end
                        local message = self.Pending.Message
                        self.Pending = nil
                        self.RecoveryCount = if removed > 0 then 0 else self.RecoveryCount + 1
                        self.NextAt = v.Clock + math.min(8, self.RecoveryCount + 1)
                        self.Status = "Inventario sincronizado; aguardando proxima tentativa"
                        if self.RecoveryCount >= 5 then self:Fail(message or "O servidor nao aplicou a fusao apos 5 tentativas") end
                    else
                        self.Pending.SyncSerial = self.SyncSerial
                        self.SyncFailures += 1
                        if self.SyncFailures >= 3 then self:Fail("Falha de conexao ao consultar o inventario") end
                    end
                    return
                end
                if self.Pending.ResultSeen or v.Clock - self.Pending.SentAt >= 3 then
                    self.Status = "Sincronizando inventario automaticamente"
                    self:RequestSync(v.Clock)
                end
                return
            end
        end
        if self.Blocked then return end
        if not v.Enabled and not v.Manual then self.Status = "Desligado"; return end
        if v.Paused then self.Status = "Pausado durante trial / carregamento"; return end
        if v.Rolling then self.Status = "Aguardando intervalo entre as aberturas"; return end
        local plan = self:Plan(v)
        self.Status = plan.Status
        if not plan.Target then
            if v.TargetUID then adapters.pause("O destino nao esta mais no inventario") end
            return
        end
        if plan.Stop then adapters.pause(plan.Status); return end
        if #plan.UIDs == 0 or v.Clock < self.NextAt then return end
        self.Pending = {TargetUID = plan.Target.UID, UIDs = plan.UIDs, SentAt = v.Clock, SyncSerial = self.SyncSerial}
        self.NextAt = v.Clock + math.max(3, tonumber(v.Interval) or 5)
        self.Status = "Enviando " .. #plan.UIDs .. " materiais para " .. tostring(plan.Target.Name)
        adapters.send(plan.Target.UID, plan.UIDs)
    end
    return c
end
-- END AUTO FUSE CONTROLLER

local fuseTab = window:CreateTab({name = "Auto Fuse"})
local function pauseFuse(message)
    setthreadidentity(8)
    options.autoFuse = false
    hub.ManualFuse = false
    if hub.Controls.autoFuse then hub.Controls.autoFuse:Set(false, true) end
    if message then notify(message) end
end
hub.Fuse = createFuseController({
    send = function(targetUID, materialUIDs) send("Fuse", targetUID, materialUIDs) end,
    sync = function(done)
        task.spawn(function()
            local ok, data = pcall(function() return remotes.GetSnapshot:InvokeServer() end)
            if not hub.Alive then return end
            local valid = ok and type(data) == "table" and type(data.Inventory) == "table"
            if valid and (not snapshot.SnapshotVersion or not data.SnapshotVersion or data.SnapshotVersion >= snapshot.SnapshotVersion) then
                snapshot = data; hub.Snapshot = data
            end
            done(valid)
        end)
    end,
    pause = pauseFuse,
    log = function(message) log:Append(message) end,
})
local function fuseView(now, paused)
    return {Clock = now, Inventory = snapshot.Inventory, TargetUID = options.fuseTarget,
        Rarities = options.fuseRarities, IncludeShiny = options.fuseShiny,
        BatchSize = options.fuseBatch, MaxLevel = config.Game.MaxFighterLevel or 70,
        Interval = options.fuseInterval, Enabled = options.autoFuse,
        Manual = hub.ManualFuse == true, Paused = paused == true,
        Rolling = player:GetAttribute("StarDropInProgress") == true or reveal.IsPlaying()}
end
hub.FuseView = fuseView
local targetUIDByLabel, targetLabelByUID = {}, {}
local syncingFuseTargets = false
local fuseTargetDropdown = fuseTab:CreateDropdown({name = "Boneco que recebera o XP",
    options = {}, placeholder = "Escolha no inventario", forgetState = true,
    callback = function(label)
        if syncingFuseTargets then return end
        local uid = targetUIDByLabel[label]
        if uid ~= options.fuseTarget then pauseFuse() end
        options.fuseTarget = uid
    end})
hub.Controls.fuseTarget = fuseTargetDropdown
hub.Controls.fuseRarities = fuseTab:CreateDropdown({name = "Raridades usadas como material",
    options = {"Common", "Rare", "Epic", "Legendary", "Mythical", "Secret"},
    multiSelect = true, value = {}, forgetState = true,
    callback = function(values)
        pauseFuse()
        options.fuseRarities = table.clone(values)
    end})
fuseTab:CreateToggle({name = "Incluir shinies como material", value = false, forgetState = true,
    description = "Somente das raridades selecionadas. Equipados, travados e o inicial continuam protegidos.",
    callback = function(value) pauseFuse(); options.fuseShiny = value end})
slider(fuseTab, "Materiais por lote", "fuseBatch", 1, 50, 1)
slider(fuseTab, "Intervalo entre lotes (s)", "fuseInterval", 3, 30, 1)
toggle(fuseTab, "Ativar Auto Fuse", "autoFuse", "Consome os materiais elegiveis e transfere o XP ao destino escolhido, incluindo novos rolls.")
local fuseSummary = fuseTab:CreateText({name = "Previa da fusao", text = "Escolha o destino e as raridades."})
local fuseSignature = nil
local function refreshFuseTargets()
    local labels, byLabel, byUID = {}, {}, {}
    for _, f in ipairs(snapshot.Inventory or {}) do
        if type(f.UID) == "string" then
            local label = tostring(f.Name) .. " | " .. tostring(f.Rarity)
                .. (f.Shiny and " | SHINY" or "") .. " | " .. f.UID
            table.insert(labels, label)
            byLabel[label], byUID[f.UID] = f.UID, label
        end
    end
    table.sort(labels)
    local signature = table.concat(labels, "\n")
    if signature ~= fuseSignature then
        setthreadidentity(8)
        fuseSignature = signature
        targetUIDByLabel, targetLabelByUID = byLabel, byUID
        syncingFuseTargets = true
        fuseTargetDropdown:Refresh(labels)
        local selected = options.fuseTarget and targetLabelByUID[options.fuseTarget]
        fuseTargetDropdown:Set(selected or {}, true)
        syncingFuseTargets = false
        if options.fuseTarget and not selected then
            options.fuseTarget = nil
            pauseFuse("O destino saiu do inventario; selecione outro boneco")
        end
    end
end
local function refreshFuseSummary()
    refreshFuseTargets()
    local plan = hub.Fuse:Plan(fuseView(os.clock(), false))
    local target = plan.Target
    local lines = {"Estado: " .. hub.Fuse.Status}
    if target then
        table.insert(lines, "Destino: " .. tostring(target.Name) .. " | Lv." .. tostring(target.Level)
            .. " | XP " .. tostring(target.XP or 0) .. "/" .. tostring(target.XPNeeded or 0))
        table.insert(lines, "UID: " .. target.UID)
    end
    table.insert(lines, plan.Status)
    table.insert(lines, "Elegiveis: " .. plan.Eligible .. " | Proximo lote: " .. #plan.UIDs .. " | XP base estimado: " .. plan.XP)
    local names = {}
    for i, f in ipairs(plan.Materials) do
        if i > 8 then table.insert(names, "..."); break end
        table.insert(names, tostring(f.Name) .. " [" .. tostring(f.Rarity) .. "]" .. (f.Shiny and " SHINY" or ""))
    end
    if #names > 0 then table.insert(lines, "Materiais: " .. table.concat(names, ", ")) end
    table.insert(lines, "Lotes confirmados: " .. hub.Fuse.Batches .. " | Materiais consumidos: " .. hub.Fuse.MaterialsUsed)
    setthreadidentity(8)
    fuseSummary:Set(table.concat(lines, "\n"))
end
hub.RefreshFuse = refreshFuseSummary
button(fuseTab, "Atualizar inventario", function()
    task.spawn(function()
        local ok, data = pcall(function() return remotes.GetSnapshot:InvokeServer() end)
        if not hub.Alive then return end
        if ok and type(data) == "table" then
            if not snapshot.SnapshotVersion or not data.SnapshotVersion or data.SnapshotVersion >= snapshot.SnapshotVersion then
                snapshot = data; hub.Snapshot = data
            end
            hub.Fuse:ResetAfterSync()
            refreshFuseSummary()
        else notify("Nao foi possivel atualizar o inventario") end
    end)
end)
button(fuseTab, "Fundir um lote agora", function()
    if hub.Trial and hub.Trial:IsBusy() then notify("Aguarde a saida da trial"); return end
    local plan = hub.Fuse:Plan(fuseView(os.clock(), false))
    if not plan.Target or #plan.UIDs == 0 then notify(plan.Status); return end
    hub.ManualFuse = true
end, "Consome o lote exibido na previa. O destino nunca e usado como material.")
fuseTab:CreateText({name = "Materiais protegidos", text = "Equipados, travados, o inicial e o destino nunca sao consumidos. Shinies so entram se voce ativar a opcao. Selecionar outro destino ou outras raridades pausa o Auto Fuse. F8 interrompe os proximos lotes."})
refreshFuseSummary()

local questTab = window:CreateTab({name = "Missoes"})
toggle(questTab, "Aceitar missoes automaticamente", "autoQuest", "Solicita a proxima missao da ilha atual quando disponivel.")
toggle(questTab, "Coletar upgrades prontos", "autoClaim", "Resgata apenas marcos marcados como Ready pelo servidor.")
button(questTab, "Aceitar missao desta ilha", function() send("AcceptIslandQuest", player:GetAttribute("CurrentWorld") or 1) end)
button(questTab, "Ir ate o NPC de missoes", function()
    local names = {"Savior of the Universe", "The Professor", "Division Commander", "Iyou", "Fireslayer"}
    local folder = workspace:FindFirstChild("NPC Quests")
    local npc = folder and folder:FindFirstChild(names[player:GetAttribute("CurrentWorld") or 1])
    if npc and npc:IsA("Model") then moveNear(npc:GetPivot().Position + Vector3.new(0, 0, 7), true) end
end)
local function claimReady()
    local m = snapshot.Milestones
    for id, ready in pairs(m and m.Ready or {}) do
        if ready and not (m.Unlocked and m.Unlocked[id]) then send("ClaimUpgrade", id) end
    end
end
button(questTab, "Resgatar upgrades disponiveis agora", claimReady)
local questConsole = questTab:CreateText({name = "Objetivos atuais", text = "Carregando..."})

local travelTab = window:CreateTab({name = "Ilhas"})
options.destination = worldNames[1]
dropdown(travelTab, "Destino", "destination", worldNames)
button(travelTab, "Viajar para ilha desbloqueada", function()
    local id = worldIds[options.destination]
    if id and id <= (snapshot.World or 1) then send("Travel", id) else notify("Esta ilha ainda esta bloqueada.") end
end, "Usa a viagem do jogo; eventuais requisitos continuam sendo verificados pelo servidor.")
button(travelTab, "Comprar desbloqueio da ilha selecionada", function()
    local id = worldIds[options.destination]
    if not id or id <= (snapshot.World or 1) then notify("A ilha ja esta desbloqueada."); return end
    local portals = module("IslandPortals")
    local def = portals.Get(id)
    if id ~= (snapshot.World or 1) + 1 then notify("Desbloqueie a ilha anterior primeiro."); return end
    if not def or (snapshot.Yen or 0) < (def.UnlockCost or math.huge) then notify("Yen insuficiente."); return end
    send("BuyIsland", id)
end, "Ao clicar, gasta Yen do jogo pelo preco do portal. Sem compra automatica.")
button(travelTab, "Voltar a primeira ilha", function() send("Travel", 1) end)

local visualTab = window:CreateTab({name = "Desempenho"})
for _, spec in ipairs({
    {"Modo de desempenho", "UltraPerformanceMode"},
    {"Ocultar brawlers de outros jogadores", "HideOtherPlayersFighters"},
    {"Ocultar efeitos de outros brawlers", "HideOtherBrawlerEffects"},
    {"Ocultar meus brawlers", "HideMyFighters"},
    {"Efeitos dos meus brawlers", "MyFighterEffects"},
    {"Efeitos em HD", "HDEffects"},
    {"Ocultar numeros de dano", "HideDamageIndicator"},
    {"Musica", "Music"},
    {"Acertos criticos", "CriticalHits"},
}) do nativeSetting(visualTab, spec[1], spec[2]) end
visualTab:CreateSlider({name = "Campo de visao", range = {50, 110}, value = oldFov or 70,
    increment = 1, flag = "ABR_fov", callback = function(v)
        local c = workspace.CurrentCamera
        if c then c.FieldOfView = v end
    end})
toggle(visualTab, "Velocidade personalizada", "customWalk", "Ajuste local; o servidor pode limitar a movimentacao.")
slider(visualTab, "Velocidade", "walk", 20, 60)

local utilTab = window:CreateTab({name = "Utilitarios"})
local redeemCode = ""
utilTab:CreateInput({name = "Codigo de recompensa", value = "", forgetState = true,
    callback = function(v) redeemCode = v end})
button(utilTab, "Resgatar codigo informado", function()
    local code = redeemCode:match("^%s*(.-)%s*$")
    if code and code ~= "" then send("RedeemCode", code) end
end)
button(utilTab, "Salvar posicao atual", function()
    local r = root()
    if r then hub.SavedPosition = r.CFrame; hub.SavedWorld = player:GetAttribute("CurrentWorld"); notify("Posicao salva nesta sessao.") end
end)
button(utilTab, "Voltar a posicao salva", function()
    local r = root()
    if r and hub.SavedPosition and hub.SavedWorld == player:GetAttribute("CurrentWorld") then
        r.CFrame = hub.SavedPosition
    else notify("Salve uma posicao nesta ilha primeiro.") end
end)
button(utilTab, "Restaurar campo de visao e velocidade", function()
    options.customWalk = false
    if hub.Controls.customWalk then hub.Controls.customWalk:Set(false, true) end
    local h = humanoid()
    if h then h.WalkSpeed = oldWalk[h] or config.Game.PlayerWalkSpeed or 20 end
    if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = oldFov or 70 end
end)
button(utilTab, "Esconder menu (Right Ctrl para voltar)", function() window:Hide() end)
button(utilTab, "Fechar menu e encerrar automacoes", hub.Cleanup)

local function acceptSnapshot(data)
    if type(data) == "table" and (not snapshot.SnapshotVersion or not data.SnapshotVersion or data.SnapshotVersion >= snapshot.SnapshotVersion) then
        snapshot = data
        hub.Snapshot = data
    end
end
hub.Snapshot = snapshot
connect(remotes.SnapshotChanged.OnClientEvent, acceptSnapshot)
local pending, lastOpen, retryAfter = false, -math.huge, 0
local rarityRank = {Common = 1, Rare = 2, Epic = 3, Legendary = 4, Mythical = 5, Secret = 6}
connect(remotes.ActionResult.OnClientEvent, function(ok, message, data, tag)
    hub.Fuse:OnResult(ok, message, data, tag)
    if tag == "StarOpen" then
        pending = false
        if ok and type(data) == "table" then
            for _, fighter in ipairs(data) do
                hub.Opens += 1
                log:Append("Obtido: " .. tostring(fighter.Name) .. " [" .. tostring(fighter.Rarity) .. "]" .. (fighter.Shiny and " SHINY" or ""))
                local rank = rarityRank[fighter.Rarity] or 0
                if (options.stopRare == "Shiny" and fighter.Shiny)
                    or (options.stopRare == "Legendary+" and rank >= 4)
                    or (options.stopRare == "Mythical+" and rank >= 5)
                    or (options.stopRare == "Secret" and rank >= 6) then
                    options.autoOpen = false
                    hub.Controls.autoOpen:Set(false, true)
                    notify("Auto open parou: " .. tostring(fighter.Name))
                end
            end
            -- GameClient owns the normal reveal and sends StarRollFinished when done.
        elseif not ok then
            retryAfter = os.clock() + 8
            hub.OpenStatus = tostring(message or "Abertura recusada")
            log:Append(hub.OpenStatus)
        end
    elseif message and message ~= "" and (not ok or tag == "UpgradeClaim" or tag == "Code") then
        log:Append(tostring(tag or "Jogo") .. ": " .. tostring(message))
    end
end)

local function currentQuestRoles()
    local roles = {}
    local world = player:GetAttribute("CurrentWorld") or 1
    local progress = quests.Progress(snapshot, world)
    local island = config.IslandQuests and config.IslandQuests[world]
    local mission = island and island.Missions[(progress.Completed or 0) + 1]
    if progress.Active and mission then
        for _, objective in ipairs(quests.Objectives(config, world, mission, progress.Current)) do
            if objective.Count < objective.Required then roles[objective.Role] = true end
        end
    end
    return roles
end
local function validEnemy(n)
    return n and n.Parent and n:IsA("Model") and n:GetAttribute("IsGameNPC") == true
        and (n:GetAttribute("Health") or 0) > 0 and not n:GetAttribute("Defeated")
        and n:GetAttribute("WorldIndex") == (player:GetAttribute("CurrentWorld") or 1)
        and not n:GetAttribute("RaidInvulnerable") and range.Compatible(player, n)
end
local lastAttack, lastMove, lastClick = 0, 0, 0
local trialNextAttack,trialNextMove,trialNextClick,trialNextInteract = 0,0,0,0
local trialTarget: any = nil
local trialTouched: any = {}
local lastTrialTouch: any = nil
local function insideTrial()
    return player:GetAttribute("ActiveTrialId")~=nil or player:GetAttribute("InTrialLobby")==true
end
local function trialView(now)
    return {Clock=now,Time=workspace:GetServerTimeNow(),Enabled=options.autoTrial,
        Lead=options.trialLead,Grace=trialConfig.LobbyGraceSeconds or 60,
        NextAt=trialState:GetAttribute("NextAt"),LastStarted=trialState:GetAttribute("LastStartedAt"),
        Active=player:GetAttribute("ActiveTrialId"),InLobby=player:GetAttribute("InTrialLobby")==true,
        Room=player:GetAttribute("TrialRoom"),World=player:GetAttribute("CurrentWorld") or 1,
        Loading=player:GetAttribute("InitialLoading")==true,
        Dead=not humanoid() or humanoid().Health<=0,
        OtherEvent=player:GetAttribute("ActiveCastleId")~=nil or player:GetAttribute("ActiveRiftId")~=nil
            or player:GetAttribute("ActiveRaidId")~=nil}
end
local function trialAlive(n,run,room)
    return n:IsA("Model") and n:GetAttribute("IsGameNPC")==true and n:GetAttribute("TrialId")==run
        and (n:GetAttribute("Health") or 0)>0 and n:GetAttribute("Defeated")~=true
        and n:GetAttribute("TrialRoomActive")==true and not n:GetAttribute("RaidInvulnerable")
        and (not room or room==0 or n:GetAttribute("TrialRoom")==room)
end
local function trialTouch(part,now)
    local r=root()
    if not part or not part:IsA("BasePart") or not r or now<trialNextInteract then return end
    trialNextInteract=now+2
    moveNear(part.Position+Vector3.new(0,part.Size.Y*0.5+2,0),true)
    local prompt=part:FindFirstChildWhichIsA("ProximityPrompt",true)
    if prompt and prompt.Enabled then fireproximityprompt(prompt) end
    firetouchinterest(r,part,1)
    lastTrialTouch={Root=r,Part=part,Until=now+0.2}
end
local function trialCombat(v,state)
    local run=v.Active
    local room=tonumber(v.Room) or (state and tonumber(state.Room)) or 0
    local r=root()
    if not r then return "Trial: aguardando personagem" end
    local rt=workspace:FindFirstChild("TrialRuntime")
    local container=rt and rt:FindFirstChild(run)
    local folder=workspace:FindFirstChild("LiveNPCs")
    if not trialTarget or not trialTarget.Parent or not trialAlive(trialTarget,run,room) then
        trialTarget=nil
        local best=math.huge
        if folder then for _,n in ipairs(folder:GetChildren()) do
            if trialAlive(n,run,room) then
                local hp=n:GetAttribute("Health") or math.huge
                if hp<best then trialTarget=n;best=hp end
            end
        end end
    end
    if trialTarget then
        if v.Clock>=trialNextMove and range.Distance(player,trialTarget)>math.min(options.distance,10)+2 then
            trialNextMove=v.Clock+0.75
            moveNear(trialTarget:GetPivot().Position+Vector3.new(0,1,math.min(options.distance,10)),true)
        end
        if range.CanSelect(player,trialTarget) then
            local combat=player:FindFirstChild("CombatTarget")
            if v.Clock>=trialNextAttack and (not combat or (combat :: any).Value~=trialTarget) then
                trialNextAttack=v.Clock+0.75;send("AttackTarget",trialTarget)
            end
            if options.trialClick and v.Clock>=trialNextClick then
                trialNextClick=v.Clock+1/math.clamp(options.cps,1,6);send("DPC")
            end
        end
        return "Sala "..tostring(room)..": "..trialTarget.Name.." | HP "..math.floor(trialTarget:GetAttribute("Health") or 0)
    end
    local current=container and container:FindFirstChild(room==0 and "Lobby" or "Room"..room)
    local geo=current and current:FindFirstChild("CriticalGeometry")
    if not geo then return "Sala "..tostring(room)..": aguardando cenario" end
    local floor=geo:FindFirstChild("Floor")
    if not floor or not floor:IsA("BasePart") or not floor.CanCollide then return "Aguardando piso da trial" end
    local buttonPart=geo:FindFirstChild("TrialButton")
    if buttonPart and buttonPart:IsA("Model") then buttonPart=buttonPart.PrimaryPart or buttonPart:FindFirstChildWhichIsA("BasePart",true) end
    if buttonPart and buttonPart:IsA("BasePart") and not trialTouched[buttonPart] then
        trialTouched[buttonPart]=v.Clock
        trialTouch(buttonPart,v.Clock)
        return "Sala "..tostring(room)..": ativando botao"
    end
    if buttonPart and trialTouched[buttonPart] and v.Clock-trialTouched[buttonPart]>4 then
        trialTouched[buttonPart]=nil
    end
    local gate=geo:FindFirstChild("Portão")
    if not gate then for _,i in ipairs(geo:GetChildren())do if i:IsA("BasePart") and i:GetAttribute("TrialGateClosed") then gate=i;break end end end
    local nextNumber=room==0 and (tonumber(container and container:GetAttribute("TrialStartRoom")) or 1) or room+1
    local nextRoom=container and container:FindFirstChild("Room"..nextNumber)
    local nextGeo=nextRoom and nextRoom:FindFirstChild("CriticalGeometry")
    local nextFloor=nextGeo and nextGeo:FindFirstChild("Floor")
    local gateOpen=false
    if gate and gate:IsA("BasePart") then
        local closed=gate:GetAttribute("TrialGateClosed")
        gateOpen=not gate.CanCollide or (typeof(closed)=="CFrame"
            and gate.Position.Y-closed.Position.Y>math.max(5,gate.Size.Y*0.75))
    end
    if gateOpen and nextFloor and nextFloor:IsA("BasePart")
        and nextFloor.CanCollide and v.Clock>=trialNextMove then
        trialNextMove=v.Clock+1
        moveNear(nextFloor.Position+Vector3.new(0,nextFloor.Size.Y*0.5+4,0),true)
        return "Avancando para sala "..tostring(nextNumber)
    end
    return "Sala "..tostring(room)..": aguardando inimigos / abertura do portao"
end
local function pauseForTrial()
    hub.Target=nil;trialTarget=nil;hub.OpenReady=false;hub.ManualOpen=false
    send("Retreat");stopMovement()
end
hub.Trial=createTrialController({
    capture=function()
        local r=root()
        if insideTrial() then return hub.LastOverworld end
        if not r then return nil end
        return {World=player:GetAttribute("CurrentWorld") or 1,Position=r.CFrame,Options=table.clone(options)}
    end,
    pause=pauseForTrial,
    enter=function()trialRemote:FireServer("MenuEnter")end,
    exit=function(context,result)
        if result then trialRemote:FireServer("Return") end
        if insideTrial() then
            local rt=workspace:FindFirstChild("TrialRuntime")
            local id=player:GetAttribute("ActiveTrialId") or player:GetAttribute("TrialWaitingLobbyId")
            local run=rt and id and rt:FindFirstChild(id)
            local exit=run and run:FindFirstChild("LobbyReturnPortal",true)
            if exit and exit:GetAttribute("TrialLobbyExitEnabled")~=true then exit=nil end
            if not exit and player:GetAttribute("ActiveTrialId") then
                for _,part in ipairs(game:GetService("CollectionService"):GetTagged("TrialButtonExitPortal"))do
                    if part:IsA("BasePart") and part:GetAttribute("TrialId")==id
                        and part:GetAttribute("TrialButtonPortalEnabled")==true then exit=part;break end
                end
            end
            if exit and exit:IsA("BasePart") then moveNear(exit.Position+Vector3.new(0,3,0),true)
            elseif not result then return end
        end
        send("Travel",context.World)
    end,
    restore=function(context)
        local r=root()
        if r then r.CFrame=context.Position;r.AssemblyLinearVelocity=Vector3.zero end
    end,
    atOrigin=function(context)
        local r=root()
        return r and (r.Position-context.Position.Position).Magnitude<8
    end,
    resume=function(context,resume)
        trialTarget=nil;table.clear(trialTouched);hub.Target=nil;hub.LastTrialReturn=context
        if not resume then
            for _,key in ipairs({"farm","autoAttack","click","autoOpen","autoQuest","autoEquip","autoClaim","autoFuse"})do
                options[key]=false;if hub.Controls[key]then hub.Controls[key]:Set(false,true)end
            end
        end
        log:Append(resume and "Trial: ilha e posicao restauradas; farm retomado." or "Trial: retorno concluido, automacoes paradas.")
    end,
    combat=trialCombat,
    log=function(message)log:Append(message)end,
})
connect(trialRemote.OnClientEvent,function(kind,payload)hub.Trial:OnEvent(kind,payload)end)
hub.TrialView=trialView
hub.EndTrialTouch=function()
    if lastTrialTouch and lastTrialTouch.Root.Parent and lastTrialTouch.Part.Parent then
        firetouchinterest(lastTrialTouch.Root,lastTrialTouch.Part,0)
    end
    lastTrialTouch=nil
end
local function trialStep(now)
    if lastTrialTouch and now>=lastTrialTouch.Until then
        hub.EndTrialTouch()
    end
    if not insideTrial() and not hub.Trial:IsBusy() and root() then
        hub.LastOverworld={World=player:GetAttribute("CurrentWorld") or 1,Position=root().CFrame,Options=table.clone(options)}
    end
    hub.Trial:Step(trialView(now))
    hub.TrialStatus=hub.Trial.Status
end
local function autoAttackStep(now)
    if not options.autoAttack or options.farm then return end
    local r, h = root(), humanoid()
    if not r or not h or h.Health <= 0 or player:GetAttribute("InitialLoading") then
        hub.Target = nil
        hub.AttackStatus = "Aguardando personagem"
        return
    end
    local target = hub.Target
    if not validEnemy(target) or not range.CanSelect(player, target) then
        target = nil
        local nearest = math.huge
        local folder = workspace:FindFirstChild("LiveNPCs")
        if folder then
            for _, enemy in ipairs(folder:GetChildren()) do
                if not validEnemy(enemy) or not range.CanSelect(player, enemy) then continue end
                local distance = range.Distance(player, enemy)
                if distance < nearest then target = enemy; nearest = distance end
            end
        end
        hub.Target = target
    end
    if not target then
        hub.AttackStatus = "Aguardando inimigo ao alcance"
        return
    end
    hub.AttackStatus = target.Name .. " | HP " .. math.floor(target:GetAttribute("Health") or 0)
    local combat = player:FindFirstChild("CombatTarget")
    if now - lastAttack >= 1 and (not combat or (combat :: any).Value ~= target) then
        lastAttack = now
        send("AttackTarget", target)
    end
end
local function farmStep(now)
    if not options.farm then return end
    local r = root()
    if not r then hub.FarmStatus = "Aguardando personagem"; return end
    local target = hub.Target
    local activeStar = options.autoOpen and hub.OpenReady and stars[options.star]
    local activeAnchor = activeStar and starPart(activeStar)
    if target and target.Parent and activeAnchor and (target:GetPivot().Position - activeAnchor.Position).Magnitude > 100 then
        target = nil
        hub.Target = nil
    end
    if not validEnemy(target) then
        target = nil
        local bestScore = math.huge
        local folder = workspace:FindFirstChild("LiveNPCs")
        local needed = options.questPriority and currentQuestRoles() or {}
        local star = options.autoOpen and hub.OpenReady and stars[options.star]
        local anchor = star and starPart(star)
        if folder then
            for _, n in ipairs(folder:GetChildren()) do
                if not validEnemy(n) then continue end
                if options.enemy ~= "Todos" and n.Name ~= options.enemy then continue end
                local boss = n:GetAttribute("IsBoss") == true
                if options.bosses == "Sem chefes" and boss then continue end
                if options.bosses == "Apenas chefes" and not boss then continue end
                local pos = n:GetPivot().Position
                local d = (pos - r.Position).Magnitude
                if d > options.radius then continue end
                -- Keep both automations in range of the star instead of bouncing between destinations.
                if anchor and (pos - anchor.Position).Magnitude > 100 then continue end
                if not options.approach and not range.CanSelect(player, n) then continue end
                local hp = n:GetAttribute("Health") or math.huge
                local score = d
                if options.mode == "Menor vida" then score = hp + d * 0.01 end
                if options.mode == "Melhor Yen por vida" then score = hp / math.max(1, n:GetAttribute("BaseRewardYen") or 1) + d * 0.001 end
                if needed[n:GetAttribute("Role")] then score *= 0.001 end
                if score < bestScore then target = n; bestScore = score end
            end
        end
        hub.Target = target
    end
    if not target then hub.FarmStatus = "Nenhum alvo compativel no raio"; return end
    hub.FarmStatus = target.Name .. " | HP " .. math.floor(target:GetAttribute("Health") or 0)
    if options.approach and not (options.autoOpen and hub.OpenReady) and now - lastMove > 1
        and (target:GetPivot().Position - r.Position).Magnitude > options.distance + 4 then
        lastMove = now
        moveNear(target:GetPivot().Position + Vector3.new(0, 1, options.distance), true)
    end
    if not range.CanSelect(player, target) then
        if options.approach and now - lastMove > 1 and not (options.autoOpen and hub.OpenReady) then
            lastMove = now
            moveNear(target:GetPivot().Position + Vector3.new(0, 1, options.distance), true)
        end
        return
    end
    local combat = player:FindFirstChild("CombatTarget")
    if now - lastAttack >= 1 and (not combat or (combat :: any).Value ~= target) then
        lastAttack = now
        send("AttackTarget", target)
    end
end
local function openStep(now)
    hub.OpenReady = false
    if not options.autoOpen and not hub.ManualOpen then return end
    local manual = hub.ManualOpen == true
    hub.ManualOpen = false
    local star = stars[options.star]
    if not star or star.world ~= (player:GetAttribute("CurrentWorld") or 1) or star.world > (snapshot.World or 1) then
        hub.OpenStatus = "Viaje para a ilha da estrela selecionada"; return
    end
    local part, r = starPart(star), root()
    if not part or not r then hub.OpenStatus = "Aguardando estrela/personagem"; return end
    local price = config.GetGachaPrice(star.world, star.id, snapshot.Passes and snapshot.Passes.VIP == true, workspace:FindFirstChild(star.map, true)) or star.cost
    if policy.RollBalance(snapshot) - options.reserve < price then hub.OpenStatus = "Aguardando Yen (preco " .. tostring(price) .. ")"; return end
    hub.OpenReady = true
    if (r.Position - part.Position).Magnitude > 15 then
        hub.OpenStatus = "Aproximando da estrela"
        if options.approachStar and now - lastMove > 1 then
            lastMove = now; moveNear(part.Position + Vector3.new(0, 0, 7), true)
        end
        if manual then notify("Aproxime-se e clique em Abrir uma vez novamente.") end
        return
    end
    if options.maxOpens > 0 and hub.Opens - (hub.OpenStart or 0) >= options.maxOpens then
        options.autoOpen = false; hub.Controls.autoOpen:Set(false, true)
        hub.OpenStatus = "Limite de aberturas atingido"; return
    end
    local count = snapshot.Multipliers and snapshot.Multipliers.Opens or 1
    if #(snapshot.Inventory or {}) + count > (snapshot.Capacity or 100) then
        hub.OpenStatus = "Inventario cheio"
        if not options.pauseFull then options.autoOpen = false; hub.Controls.autoOpen:Set(false, true) end
        return
    end
    if player:GetAttribute("InitialLoading") or player:GetAttribute("StarDropInProgress") or player:GetAttribute("GameMenuOpen") or reveal.IsPlaying() then
        hub.OpenStatus = "Aguardando animacao/menu do jogo"; return
    end
    if pending or now < retryAfter or now - lastOpen < options.openDelay then
        hub.OpenStatus = "Aguardando proxima abertura"
        if pending and now - lastOpen > 18 then pending = false; retryAfter = now + 5; send("StarRollFinished") end
        return
    end
    pending = true; lastOpen = now
    hub.OpenStatus = "Abrindo " .. options.star
    send("Gacha", star.world, star.id)
end
local function refreshStatus()
    setthreadidentity(8)
    refreshFuseSummary()
    local inv, names = snapshot.Inventory or {}, {}
    for _, f in ipairs(inv) do if f.Equipped then table.insert(names, tostring(f.Name) .. " Lv." .. tostring(f.Level) .. " | DMG " .. tostring(f.Damage)) end end
    invConsole:Set("Equipados: " .. tostring(snapshot.EquippedCount or #names) .. "/" .. tostring(snapshot.EquipCapacity or 3) .. "\n" .. table.concat(names, "\n"))
    local world = player:GetAttribute("CurrentWorld") or 1
    local p = quests.Progress(snapshot, world)
    local q = config.IslandQuests and config.IslandQuests[world]
    local mission = q and q.Missions[(p.Completed or 0) + 1]
    local lines = {"Ilha " .. tostring(world) .. " | Missoes completas: " .. tostring(p.Completed or 0)}
    if p.Active and mission then
        for _, objective in ipairs(quests.Objectives(config, world, mission, p.Current)) do
            table.insert(lines, objective.Name .. ": " .. objective.Count .. "/" .. objective.Required)
        end
    else table.insert(lines, "Nenhuma missao ativa") end
    setthreadidentity(8)
    questConsole:Set(table.concat(lines, "\n"))
    trialText:Set("Estado: "..tostring(hub.Trial.Phase).."\n"..hub.TrialStatus.."\nSala: "..tostring(player:GetAttribute("TrialRoom") or "-").."\nFarm anterior preservado: "..(hub.Trial.Context and "Sim" or "Aguardando entrada"))
    local rollBalance = policy.RollBalance(snapshot)
    setthreadidentity(8)
    status:Set(string.format("Ilha: %s | Yen: %s | Yen para estrelas: %s\nInventario: %d/%d | Equipados: %s/%s\nAuto Attack: %s\nAutofarm: %s\nAuto open: %s\nTrial: %s\nBrawlers abertos nesta sessao: %d\nVariacao de Yen: %+d | Tempo: %ds\nParar tudo: F8 | Mostrar/esconder: Right Ctrl",
        tostring(world), tostring(snapshot.Yen or 0), tostring(rollBalance), #inv, snapshot.Capacity or 100,
        tostring(snapshot.EquippedCount or 0), tostring(snapshot.EquipCapacity or 3), hub.AttackStatus, hub.FarmStatus, hub.OpenStatus, hub.TrialStatus, hub.Opens,
        (snapshot.Yen or 0) - hub.InitialYen, math.floor(os.clock() - hub.Started)))
end
local lastSlow, lastUI, lastEquip = 0, 0, 0
task.spawn(function()
    while hub.Alive and not window.unloaded do
        setthreadidentity(8)
        local now = os.clock()
        local ok, err = pcall(function()
            local h = humanoid()
            if h then
                if oldWalk[h] == nil then oldWalk[h] = h.WalkSpeed end
                if options.customWalk then h.WalkSpeed = options.walk end
            end
            trialStep(now)
            local normal=not hub.Trial:IsBusy() and not insideTrial()
            hub.Fuse:Step(fuseView(now, not normal or player:GetAttribute("InitialLoading") == true))
            hub.ManualFuse = false
            if normal then
                openStep(now)
                autoAttackStep(now)
                farmStep(now)
            else
                hub.FarmStatus=options.farm and "Pausado para trial" or "Desligado"
                hub.AttackStatus=options.autoAttack and "Pausado para trial" or "Desligado"
                hub.OpenStatus=options.autoOpen and "Pausado para trial" or "Desligado"
            end
            if normal and options.click and now - lastClick >= 1 / options.cps then
                local target = player:FindFirstChild("CombatTarget")
                if target and validEnemy((target :: any).Value) then send("DPC"); lastClick = now end
            end
            if now - lastSlow > 5 then
                lastSlow = now
                if options.autoClaim then claimReady() end
                if normal and options.autoQuest then
                    local world = player:GetAttribute("CurrentWorld") or 1
                    local p = quests.Progress(snapshot, world)
                    local def = config.IslandQuests and config.IslandQuests[world]
                    if def and not p.Active and (p.Completed or 0) < #def.Missions then send("AcceptIslandQuest", world) end
                end
            end
            if options.autoEquip and now - lastEquip > 10 then lastEquip = now; send("EquipBest") end
            if now - lastUI > 1 then lastUI = now; refreshStatus() end
        end)
        if not ok then
            hub.Errors += 1
            hub.Status = tostring(err)
            if hub.Errors <= 4 then log:Append("Erro: " .. tostring(err)); warn("[ABR]", err) end
            if hub.Errors >= 4 then stopAll(); break end
        end
        task.wait(0.1)
    end
    if hub.Alive then hub.Cleanup() end
end)
connect(player:GetAttributeChangedSignal("CurrentWorld"), function() hub.Target = nil; refreshEnemies() end)
log:Append("Menu carregado. Ative as automacoes nas respectivas abas.")
notify("Menu pronto. Auto Trial disponivel; F8 para parar tudo; Right Ctrl mostra/esconde.")
return "Anime Brawlers Hub carregado"
