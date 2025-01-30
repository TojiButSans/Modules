local module = {}

local _ENV = (getgenv or getrenv or getfenv)()
local VirtualInputManager: VirtualInputManager = game:GetService("VirtualInputManager")
local CollectionService: CollectionService = game:GetService("CollectionService")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService: TeleportService = game:GetService("TeleportService")
local RunService: RunService = game:GetService("RunService")
local Players: Players = game:GetService("Players")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GunValidator: RemoteEvent = Remotes:WaitForChild("Validator2")
local CommF: RemoteFunction = Remotes:WaitForChild("CommF_")
local CommE: RemoteEvent = Remotes:WaitForChild("CommE")

local ChestModels = workspace:WaitForChild("ChestModels")
local WorldOrigin = workspace:WaitForChild("_WorldOrigin")
local Characters = workspace:WaitForChild("Characters")
local SeaBeasts = workspace:WaitForChild("SeaBeasts")
local Enemies = workspace:WaitForChild("Enemies")
local Map = workspace:WaitForChild("Map")

local EnemySpawns = WorldOrigin:WaitForChild("EnemySpawns")
local Locations = WorldOrigin:WaitForChild("Locations")

local RenderStepped = RunService.RenderStepped
local Heartbeat = RunService.Heartbeat
local Stepped = RunService.Stepped
local Player = Players.LocalPlayer

local Data = Player:WaitForChild("Data")
local Level = Data:WaitForChild("Level")
local Fragments = Data:WaitForChild("Fragments")
local Money = Data:WaitForChild("Beli")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Net = Modules:WaitForChild("Net")
  module.FastAttack = (function()
    local FastAttack = {
      Distance = 50,
      attackMobs = true,
      attackPlayers = true,
      Equipped = nil,
      Debounce = 0,
      ComboDebounce = 0,
      ShootDebounce = 0,
      M1Combo = 0,
      
      ShootsPerTarget = {
        ["Dual Flintlock"] = 2
      },
      SpecialShoots = {
        ["Skull Guitar"] = "TAP",
        ["Bazooka"] = "Position",
        ["Cannon"] = "Position"
      },
      HitboxLimbs = {"RightLowerArm", "RightUpperArm", "LeftLowerArm", "LeftUpperArm", "RightHand", "LeftHand"}
    }
    
    local RE_RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
    local RE_ShootGunEvent = Net:WaitForChild("RE/ShootGunEvent")
    local RE_RegisterHit = Net:WaitForChild("RE/RegisterHit")
    
    local SUCCESS_FLAGS, COMBAT_REMOTE_THREAD = pcall(function()
      return require(Modules.Flags).COMBAT_REMOTE_THREAD or false
    end)
    
    local SUCCESS_SHOOT, SHOOT_FUNCTION = pcall(function()
      return getupvalue(require(ReplicatedStorage.Controllers.CombatController).Attack, 9)
    end)
    
    local SUCCESS_HIT, HIT_FUNCTION = pcall(function()
      return (getmenv or getsenv)(Net)._G.SendHitsToServer
    end)
    
    local IsAlive = Module.IsAlive
    
    function FastAttack:ShootInTarget(TargetPosition: Vector3): (nil)
      local Equipped = IsAlive(Player.Character) and Player.Character:FindFirstChildOfClass("Tool")
      
      if Equipped and Equipped.ToolTip == "Gun" then
        if Equipped:FindFirstChild("Cooldown") and (tick() - self.ShootDebounce) >= Equipped.Cooldown.Value then
          if SUCCESS_SHOOT and SHOOT_FUNCTION then
            local ShootType = self.SpecialShoots[Equipped.Name] or "Normal"
            
            if ShootType == "Position" or (ShootType == "TAP" and Equipped:FindFirstChild("RemoteEvent")) then
              Equipped:SetAttribute("LocalTotalShots", (Equipped:GetAttribute("LocalTotalShots") or 0) + 1)
              GunValidator:FireServer(self:GetValidator2())
              
              if ShootType == "TAP" then
                Equipped.RemoteEvent:FireServer("TAP", TargetPosition)
              else
                RE_ShootGunEvent:FireServer(TargetPosition)
              end
              
              self.ShootDebounce = tick()
            end
          else
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1);task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1);task.wait(0.05)
            self.ShootDebounce = tick()
          end
        end
      end
    end
    
    function FastAttack:CheckStun(ToolTip: string, Character: Character, Humanoid: Humanoid): boolean
      local Stun = Character:FindFirstChild("Stun")
      local Busy = Character:FindFirstChild("Busy")
      
      if Humanoid.Sit and (ToolTip == "Sword" or ToolTip == "Melee" or ToolTip == "Gun") then
        return false
      elseif Stun and Stun.Value > 0 then -- {{ or Busy and Busy.Value }}
        return false
      end
      
      return true
    end
    
    function FastAttack:Process(assert: boolean, Enemies: Folder, BladeHits: table, Position: Vector3, Distance: number): (nil)
      if not assert then return end
      
      local HitboxLimbs = self.HitboxLimbs
      local Mobs = Enemies:GetChildren()
      
      for i = 1, #Mobs do
        local Enemy = Mobs[i]
        local BasePart = Enemy:FindFirstChild(HitboxLimbs[math.random(#HitboxLimbs)]) or Enemy.PrimaryPart
        
        if not BasePart then continue end
        
        local CanAttack = Enemy.Parent == Characters and CheckPlayerAlly(Players:GetPlayerFromCharacter(Enemy))
        
        if Enemy ~= Player.Character and (Enemy.Parent ~= Characters or CanAttack) then
          if IsAlive(Enemy) and (Position - BasePart.Position).Magnitude <= Distance then
            if not self.EnemyRootPart then
              self.EnemyRootPart = BasePart
            else
              table.insert(BladeHits, { Enemy, BasePart })
            end
          end
        end
      end
    end
    
    function FastAttack:GetAllBladeHits(Character: Character, Distance: number?): (nil)
      local Position = Character:GetPivot().Position
      local BladeHits = {}
      Distance = Distance or self.Distance
      
      self:Process(self.attackMobs, Enemies, BladeHits, Position, Distance)
      self:Process(self.attackPlayers, Characters, BladeHits, Position, Distance)
      
      return BladeHits
    end
    
    function FastAttack:GetClosestEnemyPosition(Character: Character, Distance: number?): (nil)
      local BladeHits = self:GetAllBladeHits(Character, Distance)
      
      local Distance, Closest = math.huge
      
      for i = 1, #BladeHits do
        local Magnitude = if Closest then (Closest.Position - BladeHits[i][2].Position).Magnitude else Distance
        
        if Magnitude <= Distance then
          Distance, Closest = Magnitude, BladeHits[i][2]
        end
      end
      
      return if Closest then Closest.Position else nil
    end
    
    function FastAttack:GetGunHits(Character: Character, Distance: number?)
      local BladeHits = self:GetAllBladeHits(Character, Distance)
      local GunHits = {}
      
      for i = 1, #BladeHits do
        if not GunHits[1] or (BladeHits[i][2].Position - GunHits[1].Position).Magnitude <= 10 then
          table.insert(GunHits, BladeHits[i][2])
        end
      end
      
      return GunHits
    end
    
    function FastAttack:GetCombo(): number
      local Combo = if tick() - self.ComboDebounce <= 0.4 then self.M1Combo else 0
      Combo = if Combo >= 4 then 1 else Combo + 1
      
      self.ComboDebounce = tick()
      self.M1Combo = Combo
      
      return Combo
    end
    
    function FastAttack:UseFruitM1(Character: Character, Equipped: Tool, Combo: number): (nil)
      local Position = Character:GetPivot().Position
      local EnemyList = Enemies:GetChildren()
      
      for i = 1, #EnemyList do
        local Enemy = EnemyList[i]
        local PrimaryPart = Enemy.PrimaryPart
        if IsAlive(Enemy) and PrimaryPart and (PrimaryPart.Position - Position).Magnitude <= 50 then
          local Direction = (PrimaryPart.Position - Position).Unit
          return Equipped.LeftClickRemote:FireServer(Direction, Combo)
        end
      end
    end
    
    function FastAttack:UseNormalClick(Humanoid: Humanoid, Character: Character, Cooldown: number): (nil)
      self.EnemyRootPart = nil
      local BladeHits = self:GetAllBladeHits(Character)
      
      if self.EnemyRootPart then
        RE_RegisterAttack:FireServer(Cooldown)
        
        if SUCCESS_FLAGS and COMBAT_REMOTE_THREAD and SUCCESS_HIT and HIT_FUNCTION then
          HIT_FUNCTION(self.EnemyRootPart, BladeHits)
        else
          RE_RegisterHit:FireServer(self.EnemyRootPart, BladeHits)
        end
      end
    end
    
    function FastAttack:GetValidator2()
      local v1 = getupvalue(SHOOT_FUNCTION, 15) -- v40, 15
      local v2 = getupvalue(SHOOT_FUNCTION, 13) -- v41, 13
      local v3 = getupvalue(SHOOT_FUNCTION, 16) -- v42, 16
      local v4 = getupvalue(SHOOT_FUNCTION, 17) -- v43, 17
      local v5 = getupvalue(SHOOT_FUNCTION, 14) -- v44, 14
      local v6 = getupvalue(SHOOT_FUNCTION, 12) -- v45, 12
      local v7 = getupvalue(SHOOT_FUNCTION, 18) -- v46, 18
      
      local v8 = v6 * v2                  -- v133
      local v9 = (v5 * v2 + v6 * v1) % v3 -- v134
      
      v9 = (v9 * v3 + v8) % v4
      v5 = math.floor(v9 / v3)
      v6 = v9 - v5 * v3
      v7 = v7 + 1
      
      setupvalue(SHOOT_FUNCTION, 15, v1) -- v40, 15
      setupvalue(SHOOT_FUNCTION, 13, v2) -- v41, 13
      setupvalue(SHOOT_FUNCTION, 16, v3) -- v42, 16
      setupvalue(SHOOT_FUNCTION, 17, v4) -- v43, 17
      setupvalue(SHOOT_FUNCTION, 14, v5) -- v44, 14
      setupvalue(SHOOT_FUNCTION, 12, v6) -- v45, 12
      setupvalue(SHOOT_FUNCTION, 18, v7) -- v46, 18
      
      return math.floor(v9 / v4 * 16777215), v7
    end
    
    function FastAttack:UseGunShoot(Character, Equipped)
      local ShootType = self.SpecialShoots[Equipped.Name] or "Normal"
      
      if ShootType == "Normal" then
        local Hits = self:GetGunHits(Character, 120)
        
        if #Hits > 0 then
          local Target = Hits[1].Position
          
          Equipped:SetAttribute("LocalTotalShots", (Equipped:GetAttribute("LocalTotalShots") or 0) + 1)
          GunValidator:FireServer(self:GetValidator2())
          
          for i = 1, (self.ShootsPerTarget[Equipped.Name] or 1) do
            RE_ShootGunEvent:FireServer(Target, Hits)
          end
        end
      elseif ShootType == "Position" or (ShootType == "TAP" and Equipped:FindFirstChild("RemoteEvent")) then
        local Target = self:GetClosestEnemyPosition(Character, 200)
        
        if Target then
          Equipped:SetAttribute("LocalTotalShots", (Equipped:GetAttribute("LocalTotalShots") or 0) + 1)
          GunValidator:FireServer(self:GetValidator2())
          
          if ShootType == "TAP" then
            Equipped.RemoteEvent:FireServer("TAP", Target)
          else
            RE_ShootGunEvent:FireServer(Target)
          end
        end
      end
    end
    
    function FastAttack.attack()
      if not Settings.AutoClick or (tick() - Module.AttackCooldown) <= 1 then return end
      if not IsAlive(Player.Character) then return end
      
      local self = FastAttack
      local Character = Player.Character
      local Humanoid = Character.Humanoid
      
      local Equipped = Character:FindFirstChildOfClass("Tool")
      local ToolTip = Equipped and Equipped.ToolTip
      local ToolName = Equipped and Equipped.Name
      
      if not Equipped or (ToolTip ~= "Gun" and ToolTip ~= "Melee" and ToolTip ~= "Blox Fruit" and ToolTip ~= "Sword") then
        return nil
      end
      
      local Cooldown = Equipped:FindFirstChild("Cooldown") and Equipped.Cooldown.Value or 0.3
      
      if (tick() - self.Debounce) >= Cooldown and self:CheckStun(ToolTip, Character, Humanoid) then
        local Combo = self:GetCombo()
        Cooldown += if Combo >= 4 then 0.05 else 0
        
        self.Equipped = Equipped
        self.Debounce = if Combo >= 4 and ToolTip ~= "Gun" then (tick() + 0.05) else tick()
          
        if ToolTip == "Blox Fruit" then
          if ToolName == "Ice-Ice" or ToolName == "Light-Light" then
            return self:UseNormalClick(Humanoid, Character, Cooldown)
          elseif Equipped:FindFirstChild("LeftClickRemote") then
            return self:UseFruitM1(Character, Equipped, Combo)
          end
        elseif ToolTip == "Gun" then
          if SUCCESS_SHOOT and SHOOT_FUNCTION and Settings.AutoShoot then
            return self:UseGunShoot(Character, Equipped)
          end
        else
          return self:UseNormalClick(Humanoid, Character, Cooldown)
        end
      end
    end
    local module = {}

local _ENV = (getgenv or getrenv or getfenv)()
local VirtualInputManager: VirtualInputManager = game:GetService("VirtualInputManager")
local CollectionService: CollectionService = game:GetService("CollectionService")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService: TeleportService = game:GetService("TeleportService")
local RunService: RunService = game:GetService("RunService")
local Players: Players = game:GetService("Players")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GunValidator: RemoteEvent = Remotes:WaitForChild("Validator2")
local CommF: RemoteFunction = Remotes:WaitForChild("CommF_")
local CommE: RemoteEvent = Remotes:WaitForChild("CommE")

local ChestModels = workspace:WaitForChild("ChestModels")
local WorldOrigin = workspace:WaitForChild("_WorldOrigin")
local Characters = workspace:WaitForChild("Characters")
local SeaBeasts = workspace:WaitForChild("SeaBeasts")
local Enemies = workspace:WaitForChild("Enemies")
local Map = workspace:WaitForChild("Map")

local EnemySpawns = WorldOrigin:WaitForChild("EnemySpawns")
local Locations = WorldOrigin:WaitForChild("Locations")

local RenderStepped = RunService.RenderStepped
local Heartbeat = RunService.Heartbeat
local Stepped = RunService.Stepped
local Player = Players.LocalPlayer

local Data = Player:WaitForChild("Data")
local Level = Data:WaitForChild("Level")
local Fragments = Data:WaitForChild("Fragments")
local Money = Data:WaitForChild("Beli")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Net = Modules:WaitForChild("Net")
  module.FastAttack = (function()
    local FastAttack = {
      Distance = 50,
      attackMobs = true,
      attackPlayers = true,
      Equipped = nil,
      Debounce = 0,
      ComboDebounce = 0,
      ShootDebounce = 0,
      M1Combo = 0,
      
      ShootsPerTarget = {
        ["Dual Flintlock"] = 2
      },
      SpecialShoots = {
        ["Skull Guitar"] = "TAP",
        ["Bazooka"] = "Position",
        ["Cannon"] = "Position"
      },
      HitboxLimbs = {"RightLowerArm", "RightUpperArm", "LeftLowerArm", "LeftUpperArm", "RightHand", "LeftHand"}
    }
    
    local RE_RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
    local RE_ShootGunEvent = Net:WaitForChild("RE/ShootGunEvent")
    local RE_RegisterHit = Net:WaitForChild("RE/RegisterHit")
    
    local SUCCESS_FLAGS, COMBAT_REMOTE_THREAD = pcall(function()
      return require(Modules.Flags).COMBAT_REMOTE_THREAD or false
    end)
    
    local SUCCESS_SHOOT, SHOOT_FUNCTION = pcall(function()
      return getupvalue(require(ReplicatedStorage.Controllers.CombatController).Attack, 9)
    end)
    
    local SUCCESS_HIT, HIT_FUNCTION = pcall(function()
      return (getmenv or getsenv)(Net)._G.SendHitsToServer
    end)
    
    local IsAlive = Module.IsAlive
    
    function FastAttack:ShootInTarget(TargetPosition: Vector3): (nil)
      local Equipped = IsAlive(Player.Character) and Player.Character:FindFirstChildOfClass("Tool")
      
      if Equipped and Equipped.ToolTip == "Gun" then
        if Equipped:FindFirstChild("Cooldown") and (tick() - self.ShootDebounce) >= Equipped.Cooldown.Value then
          if SUCCESS_SHOOT and SHOOT_FUNCTION then
            local ShootType = self.SpecialShoots[Equipped.Name] or "Normal"
            
            if ShootType == "Position" or (ShootType == "TAP" and Equipped:FindFirstChild("RemoteEvent")) then
              Equipped:SetAttribute("LocalTotalShots", (Equipped:GetAttribute("LocalTotalShots") or 0) + 1)
              GunValidator:FireServer(self:GetValidator2())
              
              if ShootType == "TAP" then
                Equipped.RemoteEvent:FireServer("TAP", TargetPosition)
              else
                RE_ShootGunEvent:FireServer(TargetPosition)
              end
              
              self.ShootDebounce = tick()
            end
          else
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1);task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1);task.wait(0.05)
            self.ShootDebounce = tick()
          end
        end
      end
    end
    
    function FastAttack:CheckStun(ToolTip: string, Character: Character, Humanoid: Humanoid): boolean
      local Stun = Character:FindFirstChild("Stun")
      local Busy = Character:FindFirstChild("Busy")
      
      if Humanoid.Sit and (ToolTip == "Sword" or ToolTip == "Melee" or ToolTip == "Gun") then
        return false
      elseif Stun and Stun.Value > 0 then -- {{ or Busy and Busy.Value }}
        return false
      end
      
      return true
    end
    
    function FastAttack:Process(assert: boolean, Enemies: Folder, BladeHits: table, Position: Vector3, Distance: number): (nil)
      if not assert then return end
      
      local HitboxLimbs = self.HitboxLimbs
      local Mobs = Enemies:GetChildren()
      
      for i = 1, #Mobs do
        local Enemy = Mobs[i]
        local BasePart = Enemy:FindFirstChild(HitboxLimbs[math.random(#HitboxLimbs)]) or Enemy.PrimaryPart
        
        if not BasePart then continue end
        
        local CanAttack = Enemy.Parent == Characters and CheckPlayerAlly(Players:GetPlayerFromCharacter(Enemy))
        
        if Enemy ~= Player.Character and (Enemy.Parent ~= Characters or CanAttack) then
          if IsAlive(Enemy) and (Position - BasePart.Position).Magnitude <= Distance then
            if not self.EnemyRootPart then
              self.EnemyRootPart = BasePart
            else
              table.insert(BladeHits, { Enemy, BasePart })
            end
          end
        end
      end
    end
    
    function FastAttack:GetAllBladeHits(Character: Character, Distance: number?): (nil)
      local Position = Character:GetPivot().Position
      local BladeHits = {}
      Distance = Distance or self.Distance
      
      self:Process(self.attackMobs, Enemies, BladeHits, Position, Distance)
      self:Process(self.attackPlayers, Characters, BladeHits, Position, Distance)
      
      return BladeHits
    end
    
    function FastAttack:GetClosestEnemyPosition(Character: Character, Distance: number?): (nil)
      local BladeHits = self:GetAllBladeHits(Character, Distance)
      
      local Distance, Closest = math.huge
      
      for i = 1, #BladeHits do
        local Magnitude = if Closest then (Closest.Position - BladeHits[i][2].Position).Magnitude else Distance
        
        if Magnitude <= Distance then
          Distance, Closest = Magnitude, BladeHits[i][2]
        end
      end
      
      return if Closest then Closest.Position else nil
    end
    
    function FastAttack:GetGunHits(Character: Character, Distance: number?)
      local BladeHits = self:GetAllBladeHits(Character, Distance)
      local GunHits = {}
      
      for i = 1, #BladeHits do
        if not GunHits[1] or (BladeHits[i][2].Position - GunHits[1].Position).Magnitude <= 10 then
          table.insert(GunHits, BladeHits[i][2])
        end
      end
      
      return GunHits
    end
    
    function FastAttack:GetCombo(): number
      local Combo = if tick() - self.ComboDebounce <= 0.4 then self.M1Combo else 0
      Combo = if Combo >= 4 then 1 else Combo + 1
      
      self.ComboDebounce = tick()
      self.M1Combo = Combo
      
      return Combo
    end
    
    function FastAttack:UseFruitM1(Character: Character, Equipped: Tool, Combo: number): (nil)
      local Position = Character:GetPivot().Position
      local EnemyList = Enemies:GetChildren()
      
      for i = 1, #EnemyList do
        local Enemy = EnemyList[i]
        local PrimaryPart = Enemy.PrimaryPart
        if IsAlive(Enemy) and PrimaryPart and (PrimaryPart.Position - Position).Magnitude <= 50 then
          local Direction = (PrimaryPart.Position - Position).Unit
          return Equipped.LeftClickRemote:FireServer(Direction, Combo)
        end
      end
    end
    
    function FastAttack:UseNormalClick(Humanoid: Humanoid, Character: Character, Cooldown: number): (nil)
      self.EnemyRootPart = nil
      local BladeHits = self:GetAllBladeHits(Character)
      
      if self.EnemyRootPart then
        RE_RegisterAttack:FireServer(Cooldown)
        
        if SUCCESS_FLAGS and COMBAT_REMOTE_THREAD and SUCCESS_HIT and HIT_FUNCTION then
          HIT_FUNCTION(self.EnemyRootPart, BladeHits)
        else
          RE_RegisterHit:FireServer(self.EnemyRootPart, BladeHits)
        end
      end
    end
    
    function FastAttack:GetValidator2()
      local v1 = getupvalue(SHOOT_FUNCTION, 15) -- v40, 15
      local v2 = getupvalue(SHOOT_FUNCTION, 13) -- v41, 13
      local v3 = getupvalue(SHOOT_FUNCTION, 16) -- v42, 16
      local v4 = getupvalue(SHOOT_FUNCTION, 17) -- v43, 17
      local v5 = getupvalue(SHOOT_FUNCTION, 14) -- v44, 14
      local v6 = getupvalue(SHOOT_FUNCTION, 12) -- v45, 12
      local v7 = getupvalue(SHOOT_FUNCTION, 18) -- v46, 18
      
      local v8 = v6 * v2                  -- v133
      local v9 = (v5 * v2 + v6 * v1) % v3 -- v134
      
      v9 = (v9 * v3 + v8) % v4
      v5 = math.floor(v9 / v3)
      v6 = v9 - v5 * v3
      v7 = v7 + 1
      
      setupvalue(SHOOT_FUNCTION, 15, v1) -- v40, 15
      setupvalue(SHOOT_FUNCTION, 13, v2) -- v41, 13
      setupvalue(SHOOT_FUNCTION, 16, v3) -- v42, 16
      setupvalue(SHOOT_FUNCTION, 17, v4) -- v43, 17
      setupvalue(SHOOT_FUNCTION, 14, v5) -- v44, 14
      setupvalue(SHOOT_FUNCTION, 12, v6) -- v45, 12
      setupvalue(SHOOT_FUNCTION, 18, v7) -- v46, 18
      
      return math.floor(v9 / v4 * 16777215), v7
    end
    
    function FastAttack:UseGunShoot(Character, Equipped)
      local ShootType = self.SpecialShoots[Equipped.Name] or "Normal"
      
      if ShootType == "Normal" then
        local Hits = self:GetGunHits(Character, 120)
        
        if #Hits > 0 then
          local Target = Hits[1].Position
          
          Equipped:SetAttribute("LocalTotalShots", (Equipped:GetAttribute("LocalTotalShots") or 0) + 1)
          GunValidator:FireServer(self:GetValidator2())
          
          for i = 1, (self.ShootsPerTarget[Equipped.Name] or 1) do
            RE_ShootGunEvent:FireServer(Target, Hits)
          end
        end
      elseif ShootType == "Position" or (ShootType == "TAP" and Equipped:FindFirstChild("RemoteEvent")) then
        local Target = self:GetClosestEnemyPosition(Character, 200)
        
        if Target then
          Equipped:SetAttribute("LocalTotalShots", (Equipped:GetAttribute("LocalTotalShots") or 0) + 1)
          GunValidator:FireServer(self:GetValidator2())
          
          if ShootType == "TAP" then
            Equipped.RemoteEvent:FireServer("TAP", Target)
          else
            RE_ShootGunEvent:FireServer(Target)
          end
        end
      end
    end
    
    function FastAttack.attack()
      if not Settings.AutoClick or (tick() - Module.AttackCooldown) <= 1 then return end
      if not IsAlive(Player.Character) then return end
      
      local self = FastAttack
      local Character = Player.Character
      local Humanoid = Character.Humanoid
      
      local Equipped = Character:FindFirstChildOfClass("Tool")
      local ToolTip = Equipped and Equipped.ToolTip
      local ToolName = Equipped and Equipped.Name
      
      if not Equipped or (ToolTip ~= "Gun" and ToolTip ~= "Melee" and ToolTip ~= "Blox Fruit" and ToolTip ~= "Sword") then
        return nil
      end
      
      local Cooldown = Equipped:FindFirstChild("Cooldown") and Equipped.Cooldown.Value or 0.3
      
      if (tick() - self.Debounce) >= Cooldown and self:CheckStun(ToolTip, Character, Humanoid) then
        local Combo = self:GetCombo()
        Cooldown += if Combo >= 4 then 0.05 else 0
        
        self.Equipped = Equipped
        self.Debounce = if Combo >= 4 and ToolTip ~= "Gun" then (tick() + 0.05) else tick()
          
        if ToolTip == "Blox Fruit" then
          if ToolName == "Ice-Ice" or ToolName == "Light-Light" then
            return self:UseNormalClick(Humanoid, Character, Cooldown)
          elseif Equipped:FindFirstChild("LeftClickRemote") then
            return self:UseFruitM1(Character, Equipped, Combo)
          end
        elseif ToolTip == "Gun" then
          if SUCCESS_SHOOT and SHOOT_FUNCTION and Settings.AutoShoot then
            return self:UseGunShoot(Character, Equipped)
          end
        else
          return self:UseNormalClick(Humanoid, Character, Cooldown)
        end
      end
    end
    
    table.insert(Connections, Stepped:Connect(FastAttack.attack))
    
    return FastAttack
  end)()

return module
    table.insert(Connections, Stepped:Connect(FastAttack.attack))
    
    return FastAttack
  end)()

return module
