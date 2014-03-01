if myHero.charName ~= "Jinx" then return end

--Requires
if VIP_USER then
	require "Prodiction"
	require "Collision"
end
require "AoE_Skillshot_Position"

--Variables
local target = nil
local version = 0.4
local rocket = false

--Skill table
local skillsTable = {
	skillQ = {name = "Switcheroo!", minigunRange = 525, fishRange = 525},
	skillW = {name = "Zap!", range = 1500, speed = 3.3, delay = 600, width = 60},
	skillE = {name = "Flame Chompers!", range = 900, speed = .885, delay = 375},
	skillR = {name = "Super Mega Death Rocket!", range = 2000, speed = 1.2, delay = 600, width = 120, radius = 450}
}

function OnLoad()
	if VIP_USER then
		prodiction = ProdictManager.GetInstance()
		predictionW = prodiction:AddProdictionObject(_W, skillsTable.skillW.range, skillsTable.skillW.speed * 1000, skillsTable.skillW.delay / 1000, skillsTable.skillW.width)
		predictionE = prodiction:AddProdictionObject(_E, skillsTable.skillE.range, skillsTable.skillE.speed * 1000, skillsTable.skillE.delay / 1000)
		predictionR = prodiction:AddProdictionObject(_R, skillsTable.skillR.range, skillsTable.skillR.speed * 1000, skillsTable.skillR.delay / 1000, skillsTable.skillR.width)
		wCollision = Collision(skillsTable.skillW.range, skillsTable.skillW.speed * 1000, skillsTable.skillW.delay / 1000, skillsTable.skillW.width)
	else
		predictionW = TargetPrediction(skillsTable.skillW.range, skillsTable.skillW.speed, skillsTable.skillW.delay, skillsTable.skillW.width)
		predictionE = TargetPrediction(skillsTable.skillE.range, skillsTable.skillE.speed, skillsTable.skillE.delay)
		predictionR = TargetPrediction(skillsTable.skillR.range, skillsTable.skillR.speed, skillsTable.skillR.delay, skillsTable.skillR.width)
	end

	ts = TargetSelector(TARGET_LOW_HP_PRIORITY, skillsTable.skillR.range, DAMAGE_PHYSICAL, false)
	menu()
	
	ts.name = "AesJinx"
	config:addTS(ts)
	
	print("AesJinx version: "..version.." loaded!")
end

function OnTick()
	ts:update()
	getQRange()
	getGun()

	target = ts.target
	
	if config.basicSubMenu.combo then combo() end
	if config.basicSubMenu.combo and config.aggressiveSubMenu.comboSubMenu.comboQ then rocketLauncher() end
	if config.miscSubMenu.autoQ or config.miscSubMenu.outofrangeQ then rocketLauncher() end
	if config.basicSubMenu.harass then harass() end
	if config.aggressiveSubMenu.finisherSubMenu.finishW or config.aggressiveSubMenu.finisherSubMenu.finishR then finisher() end
	if config.defensiveSubMenu.chompersSubMenu.stunChompers then chompers() end
end

function OnDraw()
	if config.drawSubMenu.drawW then DrawCircle2(myHero.x, myHero.y, myHero.z, skillsTable.skillW.range, ARGB(255, 255, 255, 255)) end
	if config.drawSubMenu.drawE then DrawCircle2(myHero.x, myHero.y, myHero.z, skillsTable.skillE.range, ARGB(255, 255, 255, 255)) end
	if config.drawSubMenu.drawR then DrawCircle2(myHero.x, myHero.y, myHero.z, skillsTable.skillR.range, ARGB(255, 255, 255, 255)) end
	if config.drawSubMenu.drawKillable then
		for i, enemy in pairs(GetEnemyHeroes()) do
			local rDamage = getDmg("R", enemy, myHero)
			
			if ValidTarget(enemy) and rDamage > enemy.health then
				PrintFloatText(enemy, 0, "Killable target with ultimate")
				DrawCircle2(enemy.x, enemy.y, enemy.z, 150, ARGB(255, 255, 255, 0))
				DrawCircle2(enemy.x, enemy.y, enemy.z, 200, ARGB(255, 255, 255, 0))
				DrawCircle2(enemy.x, enemy.y, enemy.z, 250, ARGB(255, 255, 255, 0))
			end
		end
	end
end

function combo()
	if target ~= nil then
		if config.aggressiveSubMenu.comboSubMenu.comboW then
			local wPosition = predictionW:GetPrediction(target)
			
			if wPosition ~= nil and myHero:CanUseSpell(_W) and ValidTarget(target) and GetDistance(wPosition) < skillsTable.skillW.range then
				if VIP_USER then
					if not wCollision:GetMinionCollision(myHero, wPosition) then
						CastSpell(_W, wPosition.x, wPosition.z)
					end
				else
					if not GetMinionCollision(myHero, target, skillsTable.skillW.width) then
						CastSpell(_W, wPosition.x, wPosition.z)
					end
				end
			end
		end

		if config.aggressiveSubMenu.comboSubMenu.comboE then
			local ePosition = predictionE:GetPrediction(target)

			if ePosition ~= nil and myHero:CanUseSpell(_E) and ValidTarget(target) and GetDistance(ePosition) < skillsTable.skillE.range then
				CastSpell(_E, ePosition.x, ePosition.z)
			end
		end

		if config.aggressiveSubMenu.comboSubMenu.comboR then
			local aoeRPosition = GetAoESpellPosition(skillsTable.skillR.radius, target, skillsTable.skillR.delay)

			if aoeRPosition ~= nil and myHero:CanUseSpell(_R) and ValidTarget(target) and GetDistance(aoeRPosition) < skillsTable.skillR.range then
				CastSpell(_R, aoeRPosition.x, aoeRPosition.z)
			end
		end
	end
end

function harass()
	if target ~= nil then
		if config.aggressiveSubMenu.harassSubMenu.harassW then
			local wPosition = predictionW:GetPrediction(target)
			
			if wPosition ~= nil and myHero:CanUseSpell(_W) and ValidTarget(target) and GetDistance(wPosition) < skillsTable.skillW.range and checkManaHarass() then
				if VIP_USER then
					if not wCollision:GetMinionCollision(myHero, wPosition) then
						CastSpell(_W, wPosition.x, wPosition.z)
					end
				else
					if not GetMinionCollision(myHero, target, skillsTable.skillW.width) then
						CastSpell(_W, wPosition.x, wPosition.z)
					end
				end
			end
		end
	end
end

function finisher()
	if config.aggressiveSubMenu.finisherSubMenu.finishW then
		for i, enemy in pairs(GetEnemyHeroes()) do
			local wPosition = predictionW:GetPrediction(enemy)
			local wDamage = getDmg("W", enemy, myHero)

			if wPosition ~= nil and myHero:CanUseSpell(_W) and ValidTarget(enemy) and GetDistance(wPosition) < skillsTable.skillW.range and wDamage > enemy.health then
				if VIP_USER then
					if not wCollision:GetMinionCollision(myHero, wPosition) then
						CastSpell(_W, wPosition.x, wPosition.z)
					end
				else
					if not GetMinionCollision(myHero, enemy, skillsTable.skillW.width) then
						CastSpell(_W, wPosition.x, wPosition.z)
					end
				end
			end
		end
	end

	if config.aggressiveSubMenu.finisherSubMenu.finishR then
		for i, enemy in pairs(GetEnemyHeroes()) do
			local rPosition = predictionR:GetPrediction(enemy)
			local rDamage = getDmg("R", enemy, myHero)

			if rPosition ~= nil and myHero:CanUseSpell(_R)and ValidTarget(enemy) and GetPredictionHealth(enemy, skillsTable.skillR.delay) + 100 < rDamage and GetDistance(rPosition) < skillsTable.skillR.range and rDamage > enemy.health then
				CastSpell(_R, rPosition.x, rPosition.z)
			end
		end
	end
end

function chompers()
	if config.defensiveSubMenu.chompersSubMenu.stunChompers then
		for i, enemy in pairs(GetEnemyHeroes()) do				
			if myHero:CanUseSpell(_E) and GetDistance(enemy) < skillsTable.skillE.range and not enemy.canMove then
				CastSpell(_E, enemy.x, enemy.z)
			end
		end
	end
end

function rocketLauncher()
	if target ~= nil then
		if myHero:CanUseSpell(_Q) and GetDistance(target) <= skillsTable.skillQ.minigunRange and rocket == true then
			CastSpell(_Q)
		elseif myHero:CanUseSpell(_Q) and GetDistance(target) >= skillsTable.skillQ.minigunRange and GetDistance(target) <= skillsTable.skillQ.fishRange and rocket == false then
			CastSpell(_Q)
		elseif myHero:CanUseSpell(_Q) and GetDistance(target) > skillsTable.skillQ.fishRange + 300 and rocket == true then
			CastSpell(_Q)
		end
	end

	if target == nil and rocket == true then
		CastSpell(_Q)
	end
end

function checkManaHarass()
	if myHero.mana >= myHero.maxMana * (config.managementSubMenu.manaHarass / 100) then
		return true
	else
		return false
	end
end

function checkManaRocket()
	if myHero.mana >= myHero.maxMana * (config.managementSubMenu.manaRocket / 100) then
		return true
	else
		return false
	end 
end

function getGun()
	if myHero.range == 525.5 then
		rocket = false
	elseif myHero.range > 525.5 then
		rocket = true
	end
end

function getQRange()
	if myHero:GetSpellData(_Q).level == 1 then
		skillsTable.skillQ.fishRange = 525 + 75 + 65
	elseif myHero:GetSpellData(_Q).level == 2 then
		skillsTable.skillQ.fishRange = 525 + 100 + 65
	elseif myHero:GetSpellData(_Q).level == 3 then
		skillsTable.skillQ.fishRange = 525 + 125 + 65
	elseif myHero:GetSpellData(_Q).level == 4 then
		skillsTable.skillQ.fishRange = 525 + 150 + 65
	elseif myHero:GetSpellData(_Q).level == 5 then
		skillsTable.skillQ.fishRange = 525 + 175 + 65
	else
		skillsTable.skillQ.fishRange = 525 + 65
	end
end

function DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
	radius = radius or 300
  quality = math.max(8,round(180/math.deg((math.asin((chordlength/(2*radius)))))))
  quality = 2 * math.pi / quality
  radius = radius*.92
	local points = {}
	for theta = 0, 2 * math.pi + quality, quality do
		local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
		points[#points + 1] = D3DXVECTOR2(c.x, c.y)
	end
	DrawLines2(points, width or 1, color or 4294967295)
end

function round(num) 
 if num >= 0 then return math.floor(num+.5) else return math.ceil(num-.5) end
end

function DrawCircle2(x, y, z, radius, color)
	local vPos1 = Vector(x, y, z)
	local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
	local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
	local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
	if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y }) then
		DrawCircleNextLvl(x, y, z, radius, 1, color, 20) 
	end
end

function menu()
	config = scriptConfig("AesJinx: Main menu", "aesjinx")
	-- Basic submenu
	config:addSubMenu("AesJinx: Basic settings", "basicSubMenu")
	config.basicSubMenu:addParam("combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	config.basicSubMenu:addParam("harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, 65)
	config.basicSubMenu:addParam("version", "Version:", SCRIPT_PARAM_INFO, version)
	-- Aggressive submenu
	config:addSubMenu("AesJinx: Aggressive settings", "aggressiveSubMenu")
	config.aggressiveSubMenu:addSubMenu("Combo settings", "comboSubMenu")
	config.aggressiveSubMenu.comboSubMenu:addParam("comboQ", "Use "..skillsTable.skillQ.name, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.comboSubMenu:addParam("comboW", "Use "..skillsTable.skillW.name, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.comboSubMenu:addParam("comboE", "Use "..skillsTable.skillE.name, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.comboSubMenu:addParam("comboR", "Use "..skillsTable.skillR.name, SCRIPT_PARAM_ONOFF, false)

	config.aggressiveSubMenu:addSubMenu("Harass settings", "harassSubMenu")
	config.aggressiveSubMenu.harassSubMenu:addParam("harassW" ,"Use "..skillsTable.skillW.name, SCRIPT_PARAM_ONOFF, false)

	config.aggressiveSubMenu:addSubMenu("Finisher settings", "finisherSubMenu")
	config.aggressiveSubMenu.finisherSubMenu:addParam("finishW", "Use "..skillsTable.skillW.name, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.finisherSubMenu:addParam("finishR", "Use "..skillsTable.skillR.name, SCRIPT_PARAM_ONOFF, false)

	-- Defensive submenu
	config:addSubMenu("AesJinx: Defensive settings", "defensiveSubMenu")
	config.defensiveSubMenu:addSubMenu("Chompers settings", "chompersSubMenu")
	config.defensiveSubMenu.chompersSubMenu:addParam("stunChompers", "Use "..skillsTable.skillE.name.." under stunned target",SCRIPT_PARAM_ONOFF, false)

	-- Misc submenu
	config:addSubMenu("AesJinx: Misc settings", "miscSubMenu")
	config.miscSubMenu:addParam("autoQ", "Automatically use "..skillsTable.skillQ.name, SCRIPT_PARAM_ONOFF, false)
	config.miscSubMenu:addParam("outofrangeQ", "Change to minigun, when there is no target", SCRIPT_PARAM_ONOFF, false)

	-- Management submenu
	config:addSubMenu("AesJinx: Management settings", "managementSubMenu")
	config.managementSubMenu:addParam("manaHarass", "Minimum mana to harass", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
	config.managementSubMenu:addParam("manaRocket", "Minimum mana to change gun", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
	-- Drawing submenu
	config:addSubMenu("AesJinx: Drawing settings", "drawSubMenu")
	config.drawSubMenu:addParam("drawW", "Draw "..skillsTable.skillW.name, SCRIPT_PARAM_ONOFF, false)
	config.drawSubMenu:addParam("drawE", "Draw "..skillsTable.skillE.name, SCRIPT_PARAM_ONOFF, false)
	config.drawSubMenu:addParam("drawR", "Draw "..skillsTable.skillR.name, SCRIPT_PARAM_ONOFF, false)
	config.drawSubMenu:addParam("drawKillable", "Draw killable target", SCRIPT_PARAM_ONOFF, false)
end
