function love.load()
    sigma = 5.67e-8
    window = {}
    window.width = love.graphics.getWidth()
    window.height = love.graphics.getHeight()

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
                textbox.content = ""
            else
                planet.orbitradius = tonumber(textbox.content)
                textbox.content = ""
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
        love.graphics.print("Star:")
        love.graphics.print("Mass: " .. tostring(star.mass) .. " Solar Masses / " .. string.format("%.3e", star.mass * 1.98847e30) .."kg",0,25)
        love.graphics.print("Luminosity: " .. string.format("%.3e", star.luminosity) .. " Watts",0,50)
        love.graphics.print("Radius: ".. string.format("%.3e", star.luminosity).."m",0,75)
        love.graphics.print("Temperature: " .. string.format("%.3e", star.temp).." Kelvin",0,100)
        love.graphics.print("Spectral Type: " .. star.class, 0, 125)
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
