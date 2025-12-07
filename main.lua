local love = require("love")

function love.load()
    --stefan-boltzmann constant
    sigma = 5.67e-8

    camx, camy = 0,0

    window = {}
    window.width = love.graphics.getWidth()
    window.height = love.graphics.getHeight()

    scale = 0
    maxscale = 0
    speed = 1

    textbox = {}
    textbox.hidden = false
    textbox.width = 150
    textbox.height = 25
    textbox.x = window.width / 2 - textbox.width / 2
    textbox.y = window.height / 2 - textbox.height / 2
    textbox.selected = false
    textbox.content = ""
    textbox.decimal = nil

    mouse = {}
    mouse.x = love.mouse.getX()
    mouse.y = love.mouse.getY()

    star = {}
    star.mass = 0
    star.luminosity = nil
    star.class = nil
    star.radius = nil
    star.temp = nil
    star.hzmin = nil
    star.hzmax = nil
    star.lifetime = nil
    --star.fate = nil

    planet = {}
    planet.orbitradius = 0
    planet.period = nil
    planet.selected = false

    info = {}
    info.x = 5
    info.hidden = false
end

function love.update()
    mouse.x = love.mouse.getX()
    mouse.y = love.mouse.getY()
    love.mouse.setVisible(false)
    if love.mouse.isDown(1) then
        if collision("point", mouse, textbox) then
            textbox.selected = true
        else
            textbox.selected = false
        end
    end
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        camx = camx + 5
    end
    if love.keyboard.isDown('right') or love.keyboard.isDown("d") then
        camx = camx - 5
    end
    if love.keyboard.isDown('up') or love.keyboard.isDown("w") then
        camy = camy + 5
    end
    if love.keyboard.isDown('down') or love.keyboard.isDown("s") then
        camy = camy - 5
    end
    if planet.selected then
        camx,camy = -planet.x + window.width/2,-planet.y + window.height/2
    end
    if info.hidden == true and info.x > -350 then
        info.x = info.x + ((-350) - info.x) / 10
    elseif info.hidden == false and info.x < 5 then
        info.x = info.x + (5 - info.x) / 10
    end
end

function love.keypressed(key)
    if key == "r" then
        --love.event.push("quit","restart",1)
        star.mass, planet.orbitradius = 0,0
        textbox.hidden = false
    end
    if textbox.selected then
        if key == "backspace" then
            textbox.content = string.sub(tostring(textbox.content), 1, -2)
        end
        if key == "return" then
            if star.mass == 0 then
                star.mass = tonumber(textbox.content)
                star.luminosity = (star.mass ^ 3.5) * 3.828e26
                star.radius = (star.mass ^ 0.8) * 6.957e8
                star.temp = (star.luminosity / ((4 * math.pi) * (star.radius ^ 2) * sigma)) ^ (1/4)
                star.class = specType(star.mass)
                star.hzmin = math.sqrt((star.luminosity/3.828e26)/1.7)
                star.hzcons = math.sqrt((star.luminosity/3.828e26)/1.1)
                star.hzmax = math.sqrt((star.luminosity/3.828e26)/0.356)
                star.lifetime = 10e9 * (star.mass ^ -2.5)
                textbox.content = ""
            elseif planet.orbitradius == 0 then
                planet.orbitradius = tonumber(textbox.content)
                planet.tempmin = ((1-0.9)*(star.luminosity / 3.828e26)/(16 * math.pi * sigma * planet.orbitradius^3))^(1/4)
                planet.tempmax =  ((1-0)*(star.luminosity / 3.828e26)/(16 * math.pi * sigma * planet.orbitradius^3))^(1/4)
                textbox.content = ""
                scale = (math.min(window.width,window.height)*0.9/2) / (math.max(planet.orbitradius,star.hzmax))
                maxscale = scale
                camx,camy=0,0
            end
        end
    end
    if key == "escape" then
        if planet.selected then
            planet.selected = false
        end
        camx,camy = 0,0
        scale = maxscale
    end
    if key == "i" then
        --if not info.hidden then
        --    while info.x > -500 do
        --        info.x = info.x - 5
        --    end
        --else
        --    while info.x < 5 do
        --        info.x = info.x + 5
        --    end
        --end
        info.hidden = not info.hidden
    end
end

function love.wheelmoved(x,y)
    if love.keyboard.isDown("lctrl") then
        --if y > 0 then
        --    speed = speed * 1.025
        --elseif y < 0 then
        --    speed = speed / 1.025
        --end
        --speed = math.max(1e-100,math.min(speed, 100))
    else
        if y > 0 then
            scale = scale * 1.025
        elseif y < 0 then
            scale = scale / 1.025
        end
        scale = math.abs(math.max((math.min(window.width,window.height)*0.9/2) / (math.max(planet.orbitradius,star.hzmax)),scale))
    end
end

function love.draw()
    if star.mass == 0 then
        love.graphics.print("Enter Star Mass (Solar Masses):",textbox.x, textbox.y-textbox.height)
    elseif planet.orbitradius == 0 then
        love.graphics.print("Enter Planet Orbital Radius (AU)", textbox.x, textbox.y-textbox.height)
    else
        textbox.hidden = true
    end
    if textbox.hidden == false then
        drawLogo()
        love.graphics.rectangle("line",textbox.x, textbox.y, textbox.width, textbox.height)
        love.graphics.print(textbox.content, textbox.x, textbox.y,0,1.5)
    else
        --draw habitable zone
        love.graphics.setColor(0.7,0.7,0.2)
        love.graphics.circle("fill",window.width/2 + camx, window.height/2 + camy,star.hzmax*scale)
        love.graphics.setColor(0.5,0.5,0.5)
        love.graphics.circle("fill",window.width/2 + camx, window.height/2 + camy,star.hzcons*scale)
        love.graphics.setColor(0,0,0)
        love.graphics.circle("fill",window.width/2 + camx,window.height/2 + camy,star.hzmin*scale)
        
        --draw star
        local r,g,b = starColor()
        love.graphics.setColor(r,g,b)
        love.graphics.circle("fill",window.width/2 + camx, window.height/2 + camy, math.max(10,(star.radius/6.957e8)*0.0005) * (scale / maxscale))

        --draw planet
        love.graphics.setColor(1,1,1)
        love.graphics.circle("line",window.width/2 + camx,window.height/2 + camy,planet.orbitradius*scale)
        drawPlanet()

        --draw info
        love.graphics.setColor(0,0,0)
        love.graphics.rectangle("fill",info.x-5,0,305,350)
        love.graphics.setColor(1,1,1)
        love.graphics.rectangle("line",info.x-5,0,305,350)
        love.graphics.print("Star:",info.x,0)
        love.graphics.print("Mass: " .. tostring(star.mass) .. " Solar Masses / " .. string.format("%.3e", star.mass * 1.98847e30) .."kg",info.x,25)
        love.graphics.print("Luminosity: " .. string.format("%.3e", star.luminosity) .. " Watts",info.x,50)
        love.graphics.print("Radius: ".. string.format("%.3e", star.luminosity).."m",info.x,75)
        love.graphics.print("Temperature: " .. string.format("%.3e", star.temp).." Kelvin",info.x,100)
        love.graphics.print("Spectral Type: " .. star.class, info.x, 125)
        --love.graphics.print("Habitable Zone: [".. star.hzmin .. ",".. star.hzmax .. "]" .. " , " .. tostring(planet.orbitradius > star.hzmin and planet.orbitradius < star.hzmax),info.x,150)
        love.graphics.print("Lifetime: " .. string.format("%.3e",tostring(star.lifetime)) .. " years",info.x,150)
        
        love.graphics.print("Planet:",info.x,200)
        love.graphics.print("Orbit Radius: " .. planet.orbitradius .. " AU / " .. string.format("%.3e", planet.orbitradius * 1.495979e8) .. "km",info.x,225)
        love.graphics.print("Period: " .. planet.period .. " years",info.x,250)
        love.graphics.print("Temperature: [" .. string.format("%.3e", tostring(planet.tempmin)) .. ", " .. string.format("%.3e", tostring(planet.tempmax)) .."] Celsius",info.x,275)
        --love.graphics.print("Scale: " .. scale, info.x,275)
        if planet.orbitradius > star.hzmin and planet.orbitradius < star.hzmax then
            love.graphics.print("Habitable!",info.x,325,0,1.25)
        else
            love.graphics.print("Not Habitable...",info.x,325,0,1.25)
        end
        love.graphics.print(tostring(math.floor((scale/maxscale * 100)*1000)/1000) .. "%", 0,window.height-30)
        love.graphics.print(tostring(math.floor(speed*1000)/1000) .. "x", 0,window.height-15)
    end

    love.graphics.circle("line",mouse.x, mouse.y,5)
end

function drawPlanet()
    local time = 8
    planet.period = math.sqrt(planet.orbitradius^3 / (star.mass))
    local ang = ((love.timer.getTime() * speed) / (planet.period * time)) * (2*math.pi)
    local x = window.width/2 + math.cos(ang) * (planet.orbitradius*scale)
    local y = window.height/2 + math.sin(ang) * (planet.orbitradius*scale)
    love.graphics.circle("fill",x + camx,y + camy,5*scale/maxscale)
    if love.mouse.isDown(1) and collision("point",{x=mouse.x,y=mouse.y},{x=x+camx,y=y+camy,width=50*(scale/maxscale),height=50*(scale/maxscale)}) then
        planet.selected = true
    end
    planet.x,planet.y = x,y
end

function starColor(T)
    local t = (tostring(star.class):sub(1,1)):upper()

    if t == "O" then return 0.6,0.8,1
    elseif t == "B" then return 0.7,0.8,1
    elseif t == "A" then return 0.8,0.8,1
    elseif t == "F" then return 1,1,0.9
    elseif t == "G" then return 1,0.96,0.8
    elseif t == "K" then return 1,0.75,0.4
    elseif t == "M" then return 1,0.55,0.4
    else
        return 1,1,1
    end
end

function drawLogo()
    local logo = love.graphics.newImage("stargazer.png")
    local width,height = logo:getDimensions()
    love.graphics.draw(logo,(window.width/2)-width/4,(window.height/2)-height/4 -200,0,0.5)
    --local x,y=0,0
    --local scale = 100
    --love.graphics.setColor(0.9,0.9,0.7)
    --love.graphics.polygon("fill",x,y+(scale/2),x+(scale/2),y+(scale),x+(scale),y+(scale/2),x+(scale/2),y)
    --love.graphics.setColor(1,1,1)
    --love.graphics.rectangle("fill",x+(scale/8),y+(scale/8),(scale*0.75),(scale*0.75))
    --love.graphics.print("STARGAZER",x+(scale),y+(scale/3),0,2.5)
end

function love.textinput(t)
    if textbox.selected then
        if t == "0" then
            textbox.content = tostring(tostring(textbox.content) .. "0")
            return
        end
        if t == "." then
            if #tostring(textbox.content) == 0 or string.sub(tostring(textbox.content),1,1) == "0" then
            textbox.content = "0" .. t
            return
            elseif tonumber(textbox.content) and (tonumber(textbox.content) == math.ceil(tonumber(textbox.content))) then
                if string.sub(tostring(textbox.content),-1) ~= "." then
                    textbox.content = tostring(textbox.content) .. "."
                end
                return
            end
        end
        if tonumber(textbox.content .. t) then
            textbox.content = tostring(textbox.content) .. t
            if star.mass == 0 then
                textbox.content = tostring(math.min(400, tonumber(textbox.content)))
            elseif planet.orbitradius == 0 then
                textbox.content = tostring(math.min(999999999999, tonumber(textbox.content)))
            end
        end
    end
end

function collision(string, obj1, obj2)
    if string == "point" then
        return (obj1.x >= obj2.x) and ((obj1.x - obj2.width) <= obj2.x) and (obj1.y >= obj2.y) and ((obj1.y - obj2.height) <= obj2.y)
    end
end

function specType(M)
    local classes = {
        {type="O", min=16, max=401},
        {type="B", min=2.1, max=16},
        {type="A", min=1.4,  max=2.1},
        {type="F", min=1.04,  max=1.4},
        {type="G", min=0.8,  max=1.04},
        {type="K", min=0.45,  max=0.8},
        {type="M", min=0,  max=0.45},
    }

    for _, c in ipairs(classes) do
        if M >= c.min and M < c.max then
            local frac = (c.max - M) / (c.max - c.min)
            local subclass = math.floor(frac * 10)
            if subclass > 9 then subclass = 9 end
            if subclass < 0 then subclass = 0 end
            return c.type .. tostring(subclass)
        end
    end

    if M >= 60000 then return "O0" end
    if M < 2400 then return "L?" end

    return "?"
end
