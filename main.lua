-- ╔═══════════════════════════════════════════════════════════════════════╗
-- ║  NEON SURVIVOR - WAVE ASSAULT                                         ║
-- ║  Survive les vagues! ESPACE=saut X=tir SHIFT=dash                    ║
-- ╚═══════════════════════════════════════════════════════════════════════╝

function love.load()
    love.window.setTitle("NEON SURVIVOR")
    love.window.setMode(1000, 700)
    math.randomseed(love.timer.getTime() * 1000)
    
    fonts = {
        tiny = love.graphics.newFont(10),
        small = love.graphics.newFont(12),
        normal = love.graphics.newFont(14),
        medium = love.graphics.newFont(16),
        large = love.graphics.newFont(18),
        big = love.graphics.newFont(22),
        huge = love.graphics.newFont(28),
        title = love.graphics.newFont(36),
        giant = love.graphics.newFont(52)
    }
    
    time = 0
    
    palette = {
        skyTop = {0.02, 0.0, 0.08},
        skyMid = {0.08, 0.02, 0.18},
        skyBottom = {0.15, 0.03, 0.25},
        horizon = {0.3, 0.1, 0.4},
        sun = {1, 0.4, 0.6},
        sunGlow = {1, 0.2, 0.5},
        mountain1 = {0.06, 0.02, 0.12},
        mountain2 = {0.1, 0.04, 0.18},
        mountain3 = {0.14, 0.05, 0.22},
        gridNear = {0.8, 0.2, 1, 0.6},
        neonCyan = {0.2, 0.95, 1},
        neonPink = {1, 0.2, 0.6},
        neonPurple = {0.7, 0.3, 1},
        neonYellow = {1, 0.95, 0.3},
        neonOrange = {1, 0.5, 0.2},
        neonGreen = {0.3, 1, 0.4},
        platformTop = {0.2, 0.12, 0.35},
        platformFront = {0.12, 0.06, 0.2},
        platformGlow = {0.6, 0.25, 0.9},
        virus = {1, 0.15, 0.3},
        virusDark = {0.6, 0.05, 0.15},
        white = {1, 1, 1},
        black = {0, 0, 0}
    }
    
    stars = {}
    for i = 1, 120 do
        table.insert(stars, {x = math.random(0, 1000), y = math.random(0, 350), size = math.random(1, 3), twinkle = math.random() * math.pi * 2})
    end
    
    mountains1 = generateMountains(8, 200, 300)
    mountains2 = generateMountains(6, 240, 340)
    
    particles = {}
    for i = 1, 60 do
        table.insert(particles, {x = math.random(0, 1000), y = math.random(0, 700), size = math.random(1, 3), speed = math.random(30, 100)})
    end
    
    horizonY = 380
    gravity = 1200
    
    player = {
        x = 480, y = 500,
        width = 30, height = 46,
        velocityX = 0, velocityY = 0,
        speed = 320, jumpForce = -520,
        onGround = false,
        lives = 5,
        facing = 1,
        jumpTime = 0, landTime = 0,
        dashCooldown = 0, dashActive = false, dashDirection = 0, dashTime = 0,
        shootCooldown = 0,
        invincible = 0,
        combo = 0, comboTimer = 0,
        runCycle = 0
    }
    
    projectiles = {}
    enemyProjectiles = {}
    
    platforms = {
        {x = 0, y = 620, width = 1000, height = 80, depth = 25},
        {x = 50, y = 520, width = 120, height = 14, depth = 18},
        {x = 250, y = 450, width = 130, height = 14, depth = 18},
        {x = 450, y = 520, width = 100, height = 14, depth = 18},
        {x = 620, y = 450, width = 130, height = 14, depth = 18},
        {x = 830, y = 520, width = 120, height = 14, depth = 18},
        {x = 150, y = 350, width = 140, height = 14, depth = 18},
        {x = 420, y = 380, width = 160, height = 14, depth = 18},
        {x = 700, y = 350, width = 140, height = 14, depth = 18},
        {x = 50, y = 250, width = 100, height = 14, depth = 18},
        {x = 280, y = 280, width = 120, height = 14, depth = 18},
        {x = 500, y = 250, width = 100, height = 14, depth = 18},
        {x = 700, y = 220, width = 120, height = 14, depth = 18},
        {x = 850, y = 320, width = 100, height = 14, depth = 18},
    }
    
    enemies = {}
    wave = 0
    waveTimer = 0
    waveDelay = 3
    enemiesThisWave = 0
    enemiesKilled = 0
    waveInProgress = false
    betweenWaves = true
    waveMessage = ""
    waveMessageTimer = 0
    
    powerups = {}
    screenShake = 0
    trailParticles = {}
    
    score = 0
    highscore = 0
    gameOver = false
    
    startNextWave()
end

function generateMountains(count, minY, maxY)
    local m = {}
    local sw = 1100 / count
    for i = 0, count do
        table.insert(m, {x = i * sw - 50, y = math.random(minY, maxY)})
    end
    return m
end

function startNextWave()
    wave = wave + 1
    waveInProgress = true
    betweenWaves = false
    enemiesThisWave = 5 + wave * 3
    enemiesKilled = 0
    waveMessage = "WAVE " .. wave
    waveMessageTimer = 2
    spawnTimer = 0
    spawnInterval = math.max(0.3, 1.5 - wave * 0.1)
    enemiesToSpawn = enemiesThisWave
end

function spawnEnemy()
    local types = {"runner", "shooter", "jumper", "tank"}
    local weights = {40, 20 + wave * 2, 15 + wave, 5 + wave}
    local total = 0
    for _, w in ipairs(weights) do total = total + w end
    
    local roll = math.random(1, total)
    local enemyType = "runner"
    local cumul = 0
    for i, w in ipairs(weights) do
        cumul = cumul + w
        if roll <= cumul then
            enemyType = types[i]
            break
        end
    end
    
    local spawnSide = math.random(1, 4)
    local x, y
    local platform = platforms[math.random(2, #platforms)]
    
    if spawnSide == 1 then
        x = -40
        y = platform.y - 40
    elseif spawnSide == 2 then
        x = 1040
        y = platform.y - 40
    elseif spawnSide == 3 then
        x = math.random(50, 400)
        y = -50
    else
        x = math.random(600, 950)
        y = -50
    end
    
    local enemy = {
        x = x, y = y,
        width = 36, height = 36,
        velocityX = 0, velocityY = 0,
        type = enemyType,
        alive = true,
        phase = math.random() * math.pi * 2,
        direction = x < 500 and 1 or -1,
        shootTimer = math.random() * 2,
        jumpTimer = math.random() * 1.5,
        onGround = false,
        hp = 1,
        speed = 100,
        value = 100
    }
    
    if enemyType == "runner" then
        enemy.speed = 150 + wave * 10
        enemy.width = 32
        enemy.height = 32
        enemy.value = 100
    elseif enemyType == "shooter" then
        enemy.speed = 80
        enemy.width = 38
        enemy.height = 38
        enemy.value = 200
        enemy.shootTimer = 1
    elseif enemyType == "jumper" then
        enemy.speed = 120 + wave * 5
        enemy.width = 30
        enemy.height = 30
        enemy.jumpForce = -600
        enemy.value = 150
    elseif enemyType == "tank" then
        enemy.speed = 60
        enemy.width = 50
        enemy.height = 50
        enemy.hp = 3 + math.floor(wave / 3)
        enemy.value = 500
    end
    
    table.insert(enemies, enemy)
end

function love.update(dt)
    time = time + dt
    
    for _, p in ipairs(particles) do
        p.y = p.y + p.speed * dt
        if p.y > 700 then p.y = -10; p.x = math.random(0, 1000) end
    end
    
    if screenShake > 0 then screenShake = screenShake - dt * 6 end
    if screenShake < 0 then screenShake = 0 end
    
    if waveMessageTimer > 0 then waveMessageTimer = waveMessageTimer - dt end
    
    for i = #trailParticles, 1, -1 do
        local p = trailParticles[i]
        p.life = p.life - dt
        p.x = p.x + (p.vx or 0) * dt
        p.y = p.y + (p.vy or 0) * dt
        if p.life <= 0 then table.remove(trailParticles, i) end
    end
    
    if gameOver then
        if love.keyboard.isDown("r") then love.load() end
        return
    end
    
    if waveInProgress and enemiesToSpawn > 0 then
        spawnTimer = spawnTimer + dt
        if spawnTimer >= spawnInterval then
            spawnTimer = 0
            spawnEnemy()
            enemiesToSpawn = enemiesToSpawn - 1
        end
    end
    
    if waveInProgress and enemiesToSpawn <= 0 and #enemies == 0 then
        waveInProgress = false
        betweenWaves = true
        waveTimer = 0
        waveMessage = "WAVE " .. wave .. " COMPLETE!"
        waveMessageTimer = 2
        local waveBonus = wave * 500
        score = score + waveBonus
        if math.random() < 0.5 then
            local plat = platforms[math.random(2, #platforms)]
            table.insert(powerups, {
                x = plat.x + plat.width/2,
                y = plat.y - 20,
                type = math.random() < 0.5 and "health" or "rapidfire",
                timer = 10
            })
        end
    end
    
    if betweenWaves then
        waveTimer = waveTimer + dt
        if waveTimer >= waveDelay then
            startNextWave()
        end
    end
    
    player.dashCooldown = math.max(0, player.dashCooldown - dt)
    player.shootCooldown = math.max(0, player.shootCooldown - dt)
    player.invincible = math.max(0, player.invincible - dt)
    player.comboTimer = player.comboTimer - dt
    if player.comboTimer <= 0 then player.combo = 0 end
    
    if player.dashActive then
        player.dashTime = player.dashTime - dt
        if player.dashTime <= 0 then
            player.dashActive = false
        else
            player.x = player.x + player.dashDirection * 600 * dt
            for _, platform in ipairs(platforms) do
                if checkCollision(player, platform) then
                    if player.dashDirection > 0 then player.x = platform.x - player.width
                    else player.x = platform.x + platform.width end
                    player.dashActive = false
                end
            end
            player.x = math.max(0, math.min(player.x, 1000 - player.width))
            if math.random() > 0.4 then
                table.insert(trailParticles, {
                    x = player.x + player.width/2, y = player.y + player.height/2,
                    vx = -player.dashDirection * 100, vy = math.random(-30, 30),
                    life = 0.2, maxLife = 0.2, color = "cyan"
                })
            end
        end
    end
    
    local moving = false
    player.velocityX = 0
    if not player.dashActive then
        if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
            player.velocityX = player.speed; player.facing = 1; moving = true
        end
        if love.keyboard.isDown("left") or love.keyboard.isDown("q") or love.keyboard.isDown("a") then
            player.velocityX = -player.speed; player.facing = -1; moving = true
        end
    end
    
    if moving then
        player.runCycle = player.runCycle + dt * 12
        if math.random() > 0.8 then
            table.insert(trailParticles, {
                x = player.x + player.width/2, y = player.y + player.height,
                vx = -player.velocityX * 0.1, vy = math.random(-15, -5),
                life = 0.15, maxLife = 0.15, color = "cyan"
            })
        end
    end
    
    player.velocityY = player.velocityY + gravity * dt
    if player.velocityY > 700 then player.velocityY = 700 end
    
    player.jumpTime = player.jumpTime - dt
    player.landTime = player.landTime - dt
    
    if not player.dashActive then player.x = player.x + player.velocityX * dt end
    for _, plat in ipairs(platforms) do
        if checkCollision(player, plat) then
            if player.velocityX > 0 then player.x = plat.x - player.width
            elseif player.velocityX < 0 then player.x = plat.x + plat.width end
        end
    end
    
    local wasInAir = not player.onGround
    player.y = player.y + player.velocityY * dt
    player.onGround = false
    
    for _, plat in ipairs(platforms) do
        if checkCollision(player, plat) then
            if player.velocityY > 0 then
                player.y = plat.y - player.height
                player.velocityY = 0
                player.onGround = true
                if wasInAir then player.landTime = 0.1 end
            elseif player.velocityY < 0 then
                player.y = plat.y + plat.height
                player.velocityY = 0
            end
        end
    end
    
    player.x = math.max(0, math.min(player.x, 1000 - player.width))
    if player.y > 750 then playerDie() end
    
    for i = #projectiles, 1, -1 do
        local proj = projectiles[i]
        proj.x = proj.x + proj.vx * dt
        proj.life = proj.life - dt
        for j = #enemies, 1, -1 do
            local enemy = enemies[j]
            if enemy.alive and checkCollision({x=proj.x-proj.width/2, y=proj.y-proj.height/2, width=proj.width, height=proj.height}, enemy) then
                enemy.hp = enemy.hp - 1
                if enemy.hp <= 0 then
                    killEnemy(enemy, j)
                else
                    screenShake = 0.1
                    for k = 1, 5 do
                        table.insert(trailParticles, {
                            x = enemy.x + enemy.width/2, y = enemy.y + enemy.height/2,
                            vx = math.random(-80, 80), vy = math.random(-80, 40),
                            life = 0.3, maxLife = 0.3, color = "pink"
                        })
                    end
                end
                table.remove(projectiles, i)
                break
            end
        end
        if proj.life <= 0 or proj.x < -50 or proj.x > 1050 then
            table.remove(projectiles, i)
        end
    end
    
    for i = #enemyProjectiles, 1, -1 do
        local proj = enemyProjectiles[i]
        proj.x = proj.x + proj.vx * dt
        proj.y = proj.y + proj.vy * dt
        proj.life = proj.life - dt
        if player.invincible <= 0 and checkCollision({x=proj.x-4, y=proj.y-4, width=8, height=8}, player) then
            playerDie()
            table.remove(enemyProjectiles, i)
        elseif proj.life <= 0 or proj.x < -50 or proj.x > 1050 or proj.y > 700 then
            table.remove(enemyProjectiles, i)
        end
    end
    
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]
        if enemy.alive then
            local toPlayerX = player.x - enemy.x
            local toPlayerY = player.y - enemy.y
            local dist = math.sqrt(toPlayerX^2 + toPlayerY^2)
            enemy.direction = toPlayerX > 0 and 1 or -1
            enemy.velocityY = (enemy.velocityY or 0) + gravity * dt
            if enemy.velocityY > 600 then enemy.velocityY = 600 end
            
            if enemy.type == "runner" then
                enemy.velocityX = enemy.direction * enemy.speed
            elseif enemy.type == "shooter" then
                if dist > 200 then
                    enemy.velocityX = enemy.direction * enemy.speed
                else
                    enemy.velocityX = 0
                end
                enemy.shootTimer = enemy.shootTimer - dt
                if enemy.shootTimer <= 0 then
                    enemy.shootTimer = 1.5 - wave * 0.05
                    if enemy.shootTimer < 0.5 then enemy.shootTimer = 0.5 end
                    local angle = math.atan2(toPlayerY, toPlayerX)
                    table.insert(enemyProjectiles, {
                        x = enemy.x + enemy.width/2, y = enemy.y + enemy.height/2,
                        vx = math.cos(angle) * 300, vy = math.sin(angle) * 300, life = 3
                    })
                end
            elseif enemy.type == "jumper" then
                enemy.velocityX = enemy.direction * enemy.speed
                enemy.jumpTimer = enemy.jumpTimer - dt
                if enemy.jumpTimer <= 0 and enemy.onGround then
                    enemy.velocityY = enemy.jumpForce
                    enemy.jumpTimer = math.random() * 0.8 + 0.3
                    enemy.onGround = false
                end
            elseif enemy.type == "tank" then
                enemy.velocityX = enemy.direction * enemy.speed
            end
            
            enemy.x = enemy.x + (enemy.velocityX or 0) * dt
            for _, plat in ipairs(platforms) do
                if checkCollision(enemy, plat) then
                    if enemy.velocityX > 0 then enemy.x = plat.x - enemy.width
                    elseif enemy.velocityX < 0 then enemy.x = plat.x + plat.width end
                end
            end
            
            enemy.y = enemy.y + enemy.velocityY * dt
            enemy.onGround = false
            for _, plat in ipairs(platforms) do
                if checkCollision(enemy, plat) then
                    if enemy.velocityY > 0 then
                        enemy.y = plat.y - enemy.height
                        enemy.velocityY = 0
                        enemy.onGround = true
                    elseif enemy.velocityY < 0 then
                        enemy.y = plat.y + plat.height
                        enemy.velocityY = 0
                    end
                end
            end
            
            if enemy.x < -100 or enemy.x > 1100 then enemy.x = enemy.x < 0 and -30 or 1030 end
            if enemy.y > 750 then
                enemy.y = -50
                enemy.x = math.random(100, 900)
            end
            
            if player.invincible <= 0 and checkCollision(player, enemy) then
                if player.velocityY > 0 and player.y + player.height < enemy.y + enemy.height * 0.4 then
                    enemy.hp = enemy.hp - 1
                    player.velocityY = -400
                    if enemy.hp <= 0 then
                        killEnemy(enemy, i)
                    else
                        screenShake = 0.15
                    end
                else
                    playerDie()
                end
            end
        end
    end
    
    for i = #powerups, 1, -1 do
        local p = powerups[i]
        p.timer = p.timer - dt
        if checkCollision(player, {x = p.x - 15, y = p.y - 15, width = 30, height = 30}) then
            if p.type == "health" then
                player.lives = math.min(player.lives + 1, 8)
            elseif p.type == "rapidfire" then
                player.shootCooldown = -2
            end
            table.remove(powerups, i)
            screenShake = 0.1
            for k = 1, 10 do
                table.insert(trailParticles, {
                    x = p.x, y = p.y,
                    vx = math.random(-100, 100), vy = math.random(-100, 50),
                    life = 0.4, maxLife = 0.4, color = p.type == "health" and "green" or "yellow"
                })
            end
        elseif p.timer <= 0 then
            table.remove(powerups, i)
        end
    end
    
    if score > highscore then highscore = score end
end

function killEnemy(enemy, index)
    player.combo = player.combo + 1
    player.comboTimer = 2
    local multiplier = math.min(player.combo, 10)
    local points = enemy.value * multiplier
    score = score + points
    screenShake = 0.25
    local particleCount = enemy.type == "tank" and 25 or 15
    for k = 1, particleCount do
        table.insert(trailParticles, {
            x = enemy.x + enemy.width/2, y = enemy.y + enemy.height/2,
            vx = math.random(-180, 180), vy = math.random(-180, 80),
            life = 0.6, maxLife = 0.6, color = "pink"
        })
    end
    table.insert(trailParticles, {
        x = enemy.x + enemy.width/2, y = enemy.y,
        vx = 0, vy = -50,
        life = 1, maxLife = 1, color = "score", text = "+" .. points
    })
    table.remove(enemies, index)
    enemiesKilled = enemiesKilled + 1
end

function playerDie()
    if player.invincible > 0 then return end
    player.lives = player.lives - 1
    player.invincible = 2
    player.combo = 0
    screenShake = 0.6
    for i = 1, 25 do
        table.insert(trailParticles, {
            x = player.x + player.width/2, y = player.y + player.height/2,
            vx = math.random(-200, 200), vy = math.random(-200, 100),
            life = 0.7, maxLife = 0.7, color = "cyan"
        })
    end
    if player.lives <= 0 then gameOver = true end
end

function love.keypressed(key)
    if gameOver then
        if key == "r" then love.load() end
        return
    end
    if key == "space" or key == "up" or key == "z" or key == "w" then
        if player.onGround then
            player.velocityY = player.jumpForce
            player.onGround = false
            player.jumpTime = 0.15
        end
    end
    if (key == "x" or key == "k") and player.shootCooldown <= 0 then
        local spread = math.random(-3, 3) * 0.02
        table.insert(projectiles, {
            x = player.x + player.width/2 + player.facing * 15,
            y = player.y + player.height/2 - 5,
            vx = player.facing * 600, vy = spread * 100,
            width = 14, height = 8, life = 1.5
        })
        player.shootCooldown = 0.12
        screenShake = 0.03
        for i = 1, 3 do
            table.insert(trailParticles, {
                x = player.x + player.width/2 + player.facing * 20,
                y = player.y + player.height/2 - 5,
                vx = player.facing * 50 + math.random(-30, 30),
                vy = math.random(-30, 30),
                life = 0.1, maxLife = 0.1, color = "yellow"
            })
        end
    end
    if (key == "lshift" or key == "rshift" or key == "c") and player.dashCooldown <= 0 then
        player.dashActive = true
        player.dashDirection = player.facing
        player.dashTime = 0.1
        player.dashCooldown = 0.6
        player.invincible = math.max(player.invincible, 0.15)
        screenShake = 0.1
    end
    if key == "escape" then love.event.quit() end
end

function love.draw()
    local shakeX, shakeY = 0, 0
    if screenShake > 0 then
        shakeX = math.random(-5, 5) * screenShake
        shakeY = math.random(-5, 5) * screenShake
    end
    love.graphics.push()
    love.graphics.translate(shakeX, shakeY)
    
    for i = 0, 40 do
        local t = i / 40
        local r = palette.skyTop[1] * (1-t) + palette.skyBottom[1] * t
        local g = palette.skyTop[2] * (1-t) + palette.skyBottom[2] * t
        local b = palette.skyTop[3] * (1-t) + palette.skyBottom[3] * t
        love.graphics.setColor(r, g, b)
        love.graphics.rectangle("fill", 0, i * (horizonY / 40), 1000, horizonY / 40 + 1)
    end
    
    for _, s in ipairs(stars) do
        local tw = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(time * 4 + s.twinkle))
        love.graphics.setColor(1, 1, 1, tw)
        love.graphics.rectangle("fill", s.x, s.y, s.size, s.size)
    end
    
    love.graphics.setColor(palette.sunGlow[1], palette.sunGlow[2], palette.sunGlow[3], 0.15)
    love.graphics.circle("fill", 500, 340, 90)
    love.graphics.setColor(palette.sun)
    love.graphics.circle("fill", 500, 340, 40)
    
    love.graphics.setColor(palette.mountain1)
    drawMountains(mountains1)
    love.graphics.setColor(palette.mountain2)
    drawMountains(mountains2)
    
    love.graphics.setColor(palette.neonPink[1], palette.neonPink[2], palette.neonPink[3], 0.6)
    love.graphics.rectangle("fill", 0, horizonY - 2, 1000, 4)
    
    local vanishX = 500
    for i = -15, 15 do
        local alpha = (1 - math.abs(i) / 15) * 0.4
        love.graphics.setColor(palette.gridNear[1], palette.gridNear[2], palette.gridNear[3], alpha)
        love.graphics.line(vanishX + i * 40, horizonY, vanishX + i * 160, 700)
    end
    for i = 0, 10 do
        local t = i / 10
        local y = horizonY + (700 - horizonY) * (t * t)
        love.graphics.setColor(palette.gridNear[1], palette.gridNear[2], palette.gridNear[3], t * 0.5)
        love.graphics.line(0, y, 1000, y)
    end
    
    love.graphics.setColor(palette.neonPurple[1], palette.neonPurple[2], palette.neonPurple[3], 0.3)
    for _, p in ipairs(particles) do
        love.graphics.rectangle("fill", p.x, p.y, p.size, p.size)
    end
    
    for _, plat in ipairs(platforms) do
        drawPlatform3D(plat)
    end
    
    for _, p in ipairs(powerups) do
        local pulse = 0.7 + 0.3 * math.sin(time * 5)
        local col = p.type == "health" and palette.neonGreen or palette.neonYellow
        love.graphics.setColor(col[1], col[2], col[3], 0.3)
        love.graphics.circle("fill", p.x, p.y, 20)
        love.graphics.setColor(col)
        love.graphics.circle("fill", p.x, p.y, 12 * pulse)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(fonts.normal)
        love.graphics.print(p.type == "health" and "+" or "!", p.x - 4, p.y - 8)
    end
    
    love.graphics.setColor(palette.virus)
    for _, proj in ipairs(enemyProjectiles) do
        love.graphics.circle("fill", proj.x, proj.y, 6)
        love.graphics.setColor(1, 0.5, 0.5)
        love.graphics.circle("fill", proj.x, proj.y, 3)
        love.graphics.setColor(palette.virus)
    end
    
    for _, enemy in ipairs(enemies) do
        if enemy.alive then drawEnemy(enemy) end
    end
    
    for _, proj in ipairs(projectiles) do
        love.graphics.setColor(palette.neonCyan[1], palette.neonCyan[2], palette.neonCyan[3], 0.4)
        love.graphics.rectangle("fill", proj.x - proj.vx * 0.015 - proj.width/2, proj.y - proj.height/2, 25, proj.height)
        love.graphics.setColor(palette.neonCyan)
        love.graphics.ellipse("fill", proj.x, proj.y, proj.width/2, proj.height/2)
        love.graphics.setColor(1, 1, 1)
        love.graphics.ellipse("fill", proj.x, proj.y, 4, 2)
    end
    
    for _, p in ipairs(trailParticles) do
        if p.text then
            local alpha = p.life / p.maxLife
            love.graphics.setColor(palette.neonYellow[1], palette.neonYellow[2], palette.neonYellow[3], alpha)
            love.graphics.setFont(fonts.medium)
            love.graphics.print(p.text, p.x - 20, p.y)
        else
            local alpha = (p.life / p.maxLife) * 0.8
            local col
            if p.color == "pink" then col = palette.neonPink
            elseif p.color == "yellow" then col = palette.neonYellow
            elseif p.color == "green" then col = palette.neonGreen
            else col = palette.neonCyan end
            love.graphics.setColor(col[1], col[2], col[3], alpha)
            local size = 5 * (p.life / p.maxLife)
            love.graphics.rectangle("fill", p.x - size/2, p.y - size/2, size, size)
        end
    end
    
    drawPlayer()
    love.graphics.pop()
    drawUI()
    
    if waveMessageTimer > 0 then
        local alpha = math.min(1, waveMessageTimer)
        love.graphics.setColor(0, 0, 0, 0.5 * alpha)
        love.graphics.rectangle("fill", 300, 280, 400, 80, 10, 10)
        love.graphics.setColor(palette.neonPink[1], palette.neonPink[2], palette.neonPink[3], alpha)
        love.graphics.setFont(fonts.title)
        love.graphics.printf(waveMessage, 0, 300, 1000, "center")
    end
    
    if gameOver then
        love.graphics.setColor(0, 0, 0, 0.9)
        love.graphics.rectangle("fill", 0, 0, 1000, 700)
        for i = 1, 30 do
            love.graphics.setColor(palette.virus[1], palette.virus[2], palette.virus[3], math.random() * 0.4)
            love.graphics.rectangle("fill", 0, math.random(0, 700), 1000, math.random(1, 4))
        end
        love.graphics.setColor(palette.virus)
        love.graphics.setFont(fonts.giant)
        love.graphics.printf("GAME OVER", 0, 220, 1000, "center")
        love.graphics.setColor(palette.neonYellow)
        love.graphics.setFont(fonts.huge)
        love.graphics.printf("Wave: " .. wave .. "  |  Score: " .. score, 0, 300, 1000, "center")
        love.graphics.setColor(palette.neonCyan)
        love.graphics.setFont(fonts.big)
        love.graphics.printf("Highscore: " .. highscore, 0, 350, 1000, "center")
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(fonts.large)
        love.graphics.printf("[R] Recommencer", 0, 420, 1000, "center")
    end
end

function drawMountains(mountains)
    local verts = {}
    for _, m in ipairs(mountains) do
        table.insert(verts, m.x)
        table.insert(verts, m.y)
    end
    table.insert(verts, mountains[#mountains].x)
    table.insert(verts, horizonY + 50)
    table.insert(verts, mountains[1].x)
    table.insert(verts, horizonY + 50)
    if #verts >= 6 then love.graphics.polygon("fill", verts) end
end

function drawPlatform3D(plat)
    local depth = plat.depth or 15
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.polygon("fill", 
        plat.x + 6, plat.y + plat.height + depth + 4,
        plat.x + plat.width + 6, plat.y + plat.height + depth + 4,
        plat.x + plat.width + depth * 0.6 + 6, plat.y + depth + 4,
        plat.x + depth * 0.6 + 6, plat.y + depth + 4)
    love.graphics.setColor(palette.platformFront)
    love.graphics.polygon("fill",
        plat.x, plat.y + plat.height,
        plat.x + plat.width, plat.y + plat.height,
        plat.x + plat.width + depth * 0.6, plat.y + plat.height + depth,
        plat.x + depth * 0.6, plat.y + plat.height + depth)
    love.graphics.setColor(palette.platformFront[1] * 0.6, palette.platformFront[2] * 0.6, palette.platformFront[3] * 0.6)
    love.graphics.polygon("fill",
        plat.x + plat.width, plat.y,
        plat.x + plat.width, plat.y + plat.height,
        plat.x + plat.width + depth * 0.6, plat.y + plat.height + depth,
        plat.x + plat.width + depth * 0.6, plat.y + depth)
    love.graphics.setColor(palette.platformTop)
    love.graphics.rectangle("fill", plat.x, plat.y, plat.width, plat.height)
    local glow = 0.6 + 0.3 * math.sin(time * 2 + plat.x * 0.01)
    love.graphics.setColor(palette.platformGlow[1], palette.platformGlow[2], palette.platformGlow[3], glow)
    love.graphics.setLineWidth(2)
    love.graphics.line(plat.x + 2, plat.y, plat.x + plat.width - 2, plat.y)
end

function drawEnemy(enemy)
    local pulse = 0.8 + 0.2 * math.sin(time * 8 + enemy.phase)
    local wobble = math.sin(time * 10 + enemy.phase) * 2
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.ellipse("fill", enemy.x + enemy.width/2, enemy.y + enemy.height + 5, enemy.width/2, 5)
    local glowCol = enemy.type == "shooter" and palette.neonOrange or enemy.type == "tank" and palette.neonPurple or palette.virus
    love.graphics.setColor(glowCol[1], glowCol[2], glowCol[3], 0.3)
    love.graphics.circle("fill", enemy.x + enemy.width/2, enemy.y + enemy.height/2, enemy.width * 0.8)
    local bodyCol = enemy.type == "shooter" and {1, 0.6, 0.2} or enemy.type == "jumper" and {0.8, 0.2, 0.8} or enemy.type == "tank" and {0.6, 0.15, 0.4} or palette.virus
    love.graphics.setColor(bodyCol[1] * pulse, bodyCol[2], bodyCol[3])
    love.graphics.rectangle("fill", enemy.x + wobble, enemy.y, enemy.width, enemy.height, 5, 5)
    if enemy.type == "tank" and enemy.hp > 0 then
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", enemy.x, enemy.y - 10, enemy.width, 5)
        love.graphics.setColor(palette.neonGreen)
        love.graphics.rectangle("fill", enemy.x, enemy.y - 10, enemy.width * (enemy.hp / (3 + math.floor(wave / 3))), 5)
    end
    local eyeOff = enemy.direction == 1 and 4 or -2
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", enemy.x + enemy.width * 0.2 + eyeOff + wobble, enemy.y + enemy.height * 0.2, 6, 8, 1, 1)
    love.graphics.rectangle("fill", enemy.x + enemy.width * 0.6 + eyeOff + wobble, enemy.y + enemy.height * 0.2, 6, 8, 1, 1)
    love.graphics.setColor(bodyCol)
    love.graphics.rectangle("fill", enemy.x + enemy.width * 0.2 + 2 + eyeOff + wobble + enemy.direction * 1, enemy.y + enemy.height * 0.25, 3, 5)
    love.graphics.rectangle("fill", enemy.x + enemy.width * 0.6 + 2 + eyeOff + wobble + enemy.direction * 1, enemy.y + enemy.height * 0.25, 3, 5)
end

function drawPlayer()
    local squash, stretch = 1, 1
    if player.jumpTime > 0 then stretch = 1.1; squash = 0.9
    elseif player.landTime > 0 then stretch = 0.9; squash = 1.1 end
    local px = player.x + player.width/2
    local py = player.y + player.height/2
    local pw = player.width * squash
    local ph = player.height * stretch
    local offsetY = (1 - stretch) * player.height
    if player.invincible > 0 and math.floor(time * 15) % 2 == 0 then return end
    if player.onGround then
        love.graphics.setColor(0, 0, 0, 0.35)
        love.graphics.ellipse("fill", px, player.y + player.height + 4, pw/2 + 5, 4)
    end
    local glowPulse = 0.25 + 0.15 * math.sin(time * 4)
    if player.dashActive then glowPulse = 0.9 end
    love.graphics.setColor(palette.neonCyan[1], palette.neonCyan[2], palette.neonCyan[3], glowPulse)
    love.graphics.rectangle("fill", px - pw/2 - 6, py - ph/2 - 4 + offsetY, pw + 12, ph + 8, 10, 10)
    love.graphics.setColor(0.04, 0.12, 0.18)
    love.graphics.rectangle("fill", px - pw/2, py - ph/2 + offsetY, pw, ph, 4, 4)
    love.graphics.setColor(palette.neonCyan)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", px - pw/2, py - ph/2 + offsetY, pw, ph, 4, 4)
    love.graphics.setColor(palette.neonCyan)
    love.graphics.rectangle("fill", px - pw/3, py - ph/4 + offsetY, pw * 0.66, 6, 2, 2)
    love.graphics.setColor(1, 1, 1)
    local eyeDir = player.facing == 1 and 2 or -2
    love.graphics.circle("fill", px - 4 + eyeDir, py - ph/4 + 3 + offsetY, 2)
    love.graphics.circle("fill", px + 4 + eyeDir, py - ph/4 + 3 + offsetY, 2)
    if player.combo > 1 then
        love.graphics.setColor(palette.neonYellow)
        love.graphics.setFont(fonts.small)
        love.graphics.print("x" .. player.combo, px - 8, py - ph/2 - 18 + offsetY)
    end
end

function drawUI()
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 10, 10, 200, 80, 8, 8)
    love.graphics.setColor(palette.neonCyan[1], palette.neonCyan[2], palette.neonCyan[3], 0.7)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", 10, 10, 200, 80, 8, 8)
    love.graphics.setColor(palette.neonYellow)
    love.graphics.setFont(fonts.big)
    love.graphics.print("SCORE: " .. score, 22, 18)
    love.graphics.setColor(palette.neonPink)
    love.graphics.setFont(fonts.medium)
    love.graphics.print("WAVE " .. wave, 22, 48)
    love.graphics.setColor(palette.neonCyan)
    for i = 1, player.lives do
        love.graphics.rectangle("fill", 22 + (i-1) * 22, 70, 16, 10, 2, 2)
    end
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 790, 10, 200, 50, 8, 8)
    love.graphics.setColor(palette.virus[1], palette.virus[2], palette.virus[3], 0.7)
    love.graphics.rectangle("line", 790, 10, 200, 50, 8, 8)
    love.graphics.setColor(palette.virus)
    love.graphics.setFont(fonts.normal)
    local remaining = #enemies + enemiesToSpawn
    love.graphics.print("ENEMIES: " .. remaining, 805, 18)
    local killed = enemiesKilled
    local total = enemiesThisWave
    love.graphics.setColor(0.2, 0.1, 0.1)
    love.graphics.rectangle("fill", 805, 40, 170, 10, 3, 3)
    love.graphics.setColor(palette.neonGreen)
    love.graphics.rectangle("fill", 805, 40, 170 * (killed / math.max(1, total)), 10, 3, 3)
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 10, 680, 120, 14, 4, 4)
    if player.dashCooldown <= 0 then
        love.graphics.setColor(palette.neonCyan)
        love.graphics.rectangle("fill", 10, 680, 120, 14, 4, 4)
        love.graphics.setColor(0, 0, 0)
        love.graphics.setFont(fonts.tiny)
        love.graphics.print("DASH READY", 30, 682)
    else
        love.graphics.setColor(palette.neonPurple[1], palette.neonPurple[2], palette.neonPurple[3], 0.6)
        love.graphics.rectangle("fill", 10, 680, 120 * (1 - player.dashCooldown / 0.6), 14, 4, 4)
    end
    love.graphics.setColor(0.5, 0.4, 0.6, 0.8)
    love.graphics.setFont(fonts.tiny)
    love.graphics.print("← → MOVE   SPACE JUMP   X SHOOT   SHIFT DASH", 380, 682)
end

function checkCollision(a, b)
    return a.x < b.x + b.width and a.x + a.width > b.x and a.y < b.y + b.height and a.y + a.height > b.y
end