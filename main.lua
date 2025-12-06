function love.load()
    sigma = 5.67e-8
    window = {}
    window.width = love.graphics.getWidth()
    window.height = love.graphics.getHeight()
    scale = 0
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

    planet = {}
    planet.orbitradius = 0
end

function love.update()
    mouse.x = love.mouse.getX()
    mouse.y = love.mouse.getY()

    if love.mouse.isDown(1) then
        if collision("point", mouse, textbox) then
            textbox.selected = true
        else
            textbox.selected = false
        end
    end
end

function love.keypressed(key)
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
                star.class = specType(star.temp)
                star.hzmin = math.sqrt((star.luminosity/3.828e26)/1.1)
                star.hzmax = math.sqrt((star.luminosity/3.828e26)/0.53)
                textbox.content = ""
            else
                planet.orbitradius = tonumber(textbox.content)
                textbox.content = ""
                scale = (math.max(planet.orbitradius,star.hzmax) / (window.height/2.5))^-1
            end
        end
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
        love.graphics.rectangle("line",textbox.x, textbox.y, textbox.width, textbox.height)
        love.graphics.print(textbox.content, textbox.x, textbox.y,0,1.5)
        love.graphics.circle("line",mouse.x, mouse.y,5)
    else

        love.graphics.setColor(0.7,0.7,0.2)
        love.graphics.circle("fill",window.width/2, window.height/2,star.hzmax*scale)
        love.graphics.setColor(0,0,0)
        love.graphics.circle("fill",window.width/2,window.height/2,star.hzmin*scale)

        local r,g,b = starColor()
        love.graphics.setColor(r,g,b)
        love.graphics.circle("fill",window.width /2, window.height/2, scale/10)

        love.graphics.setColor(1,1,1)
        love.graphics.circle("line",window.width/2,window.height/2,planet.orbitradius*scale)
        drawPlanet()

        love.graphics.print("Star:")
        love.graphics.print("Mass: " .. tostring(star.mass) .. " Solar Masses / " .. string.format("%.3e", star.mass * 1.98847e30) .."kg",0,25)
        love.graphics.print("Luminosity: " .. string.format("%.3e", star.luminosity) .. " Watts",0,50)
        love.graphics.print("Radius: ".. string.format("%.3e", star.luminosity).."m",0,75)
        love.graphics.print("Temperature: " .. string.format("%.3e", star.temp).." Kelvin",0,100)
        love.graphics.print("Spectral Type: " .. star.class, 0, 125)
        love.graphics.print("Habitable Zone: [".. star.hzmin .. ",".. star.hzmax .. "]" .. " , " .. tostring(planet.orbitradius > star.hzmin and planet.orbitradius < star.hzmax),0,150)
        
    end
end

function drawPlanet()
    local speed = 8
    planet.period = math.sqrt(planet.orbitradius^3 / (star.mass))
    local ang = (love.timer.getTime() / (planet.period * speed)) * (2*math.pi)
    local x = window.width/2 + math.cos(ang) * (planet.orbitradius*scale)
    local y = window.height/2 + math.sin(ang) * (planet.orbitradius*scale)
    love.graphics.circle("fill",x,y,scale/6)
end

function starColor(T)
    local t = (tostring(star.class):sub(1,1)):upper()

    if t == "O" then return 0.6,0.8,1
    elseif t == "B" then return 0.7,0.8,1
    elseif t == "A" then return 0.9,0.9,1
    elseif t == "F" then return 1,1,0.9
    elseif t == "G" then return 1,0.96,0.6
    elseif t == "K" then return 1,0.75,0.4
    elseif t == "M" then return 1,0.55,0.4
    else
        return 1,1,1
    end
end

function love.textinput(t)
    if textbox.selected then
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
            textbox.content = textbox.content .. t
            if star.mass == 0 then
                textbox.content = math.min(400, tonumber(textbox.content))
            elseif planet.orbitradius == 0 then
                textbox.content = math.min(999999999999, tonumber(textbox.content))
            end
        end
    end
end

function collision(string, obj1, obj2)
    if string == "point" then
        return (obj1.x >= obj2.x) and ((obj1.x - obj2.width) <= obj2.x) and (obj1.y >= obj2.y) and ((obj1.y - obj2.height) <= obj2.y)
    end
end

function specType(T)
    local classes = {
        {type="O", min=30000, max=60000},
        {type="B", min=10000, max=30000},
        {type="A", min=7500,  max=10000},
        {type="F", min=6000,  max=7500},
        {type="G", min=5200,  max=6000},
        {type="K", min=3700,  max=5200},
        {type="M", min=2400,  max=3700},
    }

    for _, c in ipairs(classes) do
        if T >= c.min and T < c.max then
            local frac = (c.max - T) / (c.max - c.min)
            local subclass = math.floor(frac * 10)
            if subclass > 9 then subclass = 9 end
            if subclass < 0 then subclass = 0 end
            return c.type .. tostring(subclass)
        end
    end

    if T >= 60000 then return "O0" end
    if T < 2400 then return "L?" end

    return "?"
end
