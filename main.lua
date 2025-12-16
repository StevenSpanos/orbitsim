local love = require("love")

function love.load()
    Object = require "classic"
    require "ui"

    --stefan-boltzmann constant
    sigma = 5.67e-8

    camx, camy = 0,0

    window = {}
    window.width = love.graphics.getWidth()
    window.height = love.graphics.getHeight()

    scale = 0
    maxscale = 0
    speed = 1

    textbox = UI(window.width/2 - 150/2,window.height/2 - 25/2, 150, 25,"textbox")

    info = UI(5,0,305,350)

    mouse = {}
    mouse.x = love.mouse.getX()
    mouse.y = love.mouse.getY()

    --set everything to nil except star mass. could've set it as nil but didn't.
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
    planet.mass = -1
    planet.selected = false

    buttons = {}
end

function love.update()
    mouse.x = love.mouse.getX()
    mouse.y = love.mouse.getY()
    love.mouse.setVisible(false)

    if love.mouse.isDown(1) then
        if collision("point", mouse, textbox) then --mouse selects textbox
            textbox.selected = true
        else
            textbox.selected = false
        end

        if collision("point",mouse,info) then --mouse selects infobox
            camx,camy = 0,0
            info.expanded = true
        end
    end

    --panning camera
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

    --sets the camera to the planet if selected
    if planet.selected then
        camx,camy = -planet.x + window.width/2,-planet.y + window.height/2
    end

    --moves the info box so it looks cool when closing or opening
    if info.hidden == true and info.x > -350 then
        info.x = info.x + ((-350) - info.x) / 10
    elseif info.hidden == false and info.x < 5 then
        info.x = info.x + (5 - info.x) / 10
    end
end

function love.keypressed(key)
    --restarts the app
    if key == "r" then
        love.event.push("quit","restart",1)
    end

    --textbox stuff
    if textbox.selected then
        if key == "backspace" then
            textbox.content = string.sub(tostring(textbox.content), 1, -2)
        end
        if key == "return" then
            if star.mass == 0 then
                if tonumber(textbox.content) ~= nil then
                    star.mass = tonumber(textbox.content)
                    star.luminosity = (star.mass ^ 3.5) * 3.828e26 --luminosity is proportional to mass ^ 3.5, times the luminosity of the Sun
                    star.radius = (star.mass ^ 0.8) * 6.957e8 --radius is proportional to mass ^ 0.5, times radius of the Sun
                    star.temp = (star.luminosity / ((4 * math.pi) * (star.radius ^ 2) * sigma)) ^ (1/4) --rearranged Stefan-Boltzmann Law, L = 4 * pi * r^2 * sigma * T^2
                    star.class = specType(star.mass)
                    star.hzmin = math.sqrt((star.luminosity/3.828e26)/1.7) --minimum habitable zone
                    star.hzcons = math.sqrt((star.luminosity/3.828e26)/1.1) --conservative habitable zone
                    star.hzmax = math.sqrt((star.luminosity/3.828e26)/0.356) --maximum habitable zone
                    star.lifetime = 10e9 * (star.mass ^ -2.5) --lifetime is proportional to mass ^ -2.5, multiplied by lifetime of the Sun
                    textbox.content = ""
                end
            elseif planet.orbitradius == 0 then
                if tonumber(textbox.content) ~= nil then
                planet.orbitradius = tonumber(textbox.content) -- solar constant
                local S = star.luminosity * 3.828e26 / (4 * math.pi * planet.orbitradius^2 * 1.496e11)
                planet.tempmin = ((1-0.9)*(S)/(16 * math.pi * sigma * (planet.orbitradius * 1.496e11)^3))^(1/4) --big equation. Planetary Energy Balance Equation.
                planet.tempmax =  ((1-0)*(S)/(16 * math.pi * sigma * (planet.orbitradius * 1.496e11)^3))^(1/4) --big equation again.
                planet.period = 2 * math.pi * math.sqrt(((planet.orbitradius * 1.496e11)^3) / (6.67e-11 * (star.mass * 1.989e30))) --Kepler's 3rd Law - P^2 = a^3
                --planet.mass = (4 * math.pi^2 * ((planet.orbitradius * 1.495979e11)^3)) / (6.67e-11 * planet.period^2)
                textbox.content = ""

                scale = (math.min(window.width,window.height)*0.9/2) / (math.max(planet.orbitradius,star.hzmax))
                maxscale = scale
                camx,camy=0,0

                textbox.hidden = true
                UI(window.width-55,5,50,50,"button").subID = "add"
                end
            elseif planet.mass == -1 and not textbox.hidden then
                planet.mass = tonumber(textbox.content)
                scale = (math.min(window.width,window.height)*0.9/2) / (math.max(planet.orbitradius,star.hzmax))
                maxscale = scale
                camx,camy=0,0

                textbox.hidden = true
            end
        end
    end

    if key == "escape" then
        if planet.selected then
            planet.selected = false
        end
        if info.expanded then
            info.expanded = false
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
    elseif info.expanded then
        if y > 0 then
            camy = camy + 10
        elseif y < 0 then
            camy = camy - 10
        end
        camy = math.max(-750,math.min(camy,5))
    else
        if y > 0 then
            scale = scale * 1.025
        elseif y < 0 then
            scale = scale / 1.025
        end
        scale = math.abs(math.max((math.min(window.width,window.height)*0.9/2) / (math.max(planet.orbitradius,star.hzmax)),scale))
    end
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

function love.draw()
    --love.graphics.line(window.width/2,0,window.width/2,window.height)
    if star.mass == 0 then
        love.graphics.print("Enter Star Mass (Solar Masses):",textbox.x, textbox.y-textbox.height)
        love.graphics.printf("Star mass: \n This is the mass of the star, in solar units Astronomers use Solar Masses as a unit of measurement for stars, since masses can get really large. By using solar masses, it makes it easier to not only visualize how a star might look like, but also simplify numbers so there aren't a ton of numbers with 30 zeros trailing it. 1 Solar Unit is equivalent to the mass of the Sun.",(window.width-365)/2,textbox.y+textbox.height*5,300,"center",0,1.25)
    elseif planet.orbitradius == 0 then
        love.graphics.print("Enter Planet Orbital Radius (AU)", textbox.x, textbox.y-textbox.height)
        love.graphics.printf("Planet Orbit Radius: \n A planet's orbit radius is defined by the average distance from the planet to the star. This is measured in AU, which is equivalent to the distance from the Earth to the Sun. As with star masses, this is because planet orbit radii can get rather large, so it's easier to measure it based off of something similar.",(window.width-365)/2,textbox.y+textbox.height*5,300,"center",0,1.25)
    elseif planet.mass == -1 and not textbox.hidden then
        love.graphics.print("Enter Planet Mass (Earth Masses)", textbox.x, textbox.y-textbox.height)
        love.graphics.printf("Planet Mass: \n Planet Mass is how heavy the planet is. This is measured in Earth Masses, which is the weight of the Earth. This is due to the fact that planets can get really big, and it makes it easier to track things by using Earth Masses.",(window.width-365)/2,textbox.y+textbox.height*5,300,"center",0,1.25)
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
        love.graphics.circle("fill",window.width/2 + camx, window.height/2 + camy, math.max(10,(star.radius/1.496e11)* (scale)))

        --draw planet
        love.graphics.setColor(1,1,1)
        love.graphics.circle("line",window.width/2 + camx,window.height/2 + camy,planet.orbitradius*scale)
        drawPlanet()

        --draw info
        local h = 0
        if planet.mass == -1 then
            h = 350
        else
            h = 500
        end
        love.graphics.setColor(0,0,0)
            love.graphics.rectangle("fill",info.x-5,0,305,h)
            love.graphics.setColor(1,1,1)
            love.graphics.rectangle("line",info.x-5,0,305,h)
        love.graphics.print("Star:",info.x,0)
        love.graphics.print("Mass: " .. tostring(star.mass) .. " Solar Masses / " .. string.format("%.3e", star.mass * 1.98847e30) .."kg",info.x,25)
        love.graphics.print("Luminosity: " .. string.format("%.3e", star.luminosity) .. " Watts",info.x,50)
        love.graphics.print("Radius: ".. string.format("%.3e", star.radius).."m",info.x,75)
        love.graphics.print("Temperature: " .. string.format("%.3e", star.temp).." Kelvin",info.x,100)
        love.graphics.print("Spectral Type: " .. star.class, info.x, 125)
        --love.graphics.print("Habitable Zone: [".. star.hzmin .. ",".. star.hzmax .. "]" .. " , " .. tostring(planet.orbitradius > star.hzmin and planet.orbitradius < star.hzmax),info.x,150)
        love.graphics.print("Lifetime: " .. string.format("%.3e",tostring(star.lifetime)) .. " years",info.x,150)
        
        love.graphics.print("Planet:",info.x,200)
        love.graphics.print("Orbit Radius: " .. planet.orbitradius .. " AU / " .. string.format("%.3e", planet.orbitradius * 1.495979e8) .. "km",info.x,225)
        love.graphics.print("Period: " .. planet.period .. " years",info.x,250)
        love.graphics.print("Temperature: [" .. string.format("%.2e", tostring(planet.tempmin)) .. ", " .. string.format("%.2e", tostring(planet.tempmax * 32 - 273.15)) .. "] Celsius",info.x,275)
        --love.graphics.print("Mass: " .. string.format("%.3e", planet.mass) .. "kg",info.x,300)
        --love.graphics.print("Scale: " .. scale, info.x,275)
        if planet.orbitradius > star.hzmin and planet.orbitradius < star.hzmax then
            love.graphics.print("Habitable!",info.x,325,0,1.25)
        else
            love.graphics.print("Not Habitable...",info.x,325,0,1.25)
        end
        love.graphics.print(tostring(math.floor((scale/maxscale * 100)*1000)/1000) .. "%", 0,window.height-30)
        love.graphics.print(tostring((math.max(planet.orbitradius,star.hzmax) * 1.496e8 * maxscale/scale) / (math.min(window.width, window.height) * 0.9 / 2)) .. " km per px", 0,window.height-15)
        if info.expanded then
            love.graphics.setColor(0,0,0)
            love.graphics.rectangle("fill",0,0,window.width,window.height)
            love.graphics.setColor(1,1,1)
            love.graphics.print("What does this mean?",0,camy,0,1.5)

            printInfo("Star mass: \n This is the mass of the star, in solar units \n Astronomers use Solar Masses as a unit of measurement for stars, since masses can get really large. \n By using solar masses, it makes it easier to not only visualize how a star might look like, but also simplify numbers so there aren't a ton of numbers with 30 zeros trailing it. 1 Solar Unit is equivalent to the mass of the Sun.",30)
            printInfo("Star luminosity: \n This is how bright a star is, measured in Watts.\n Usually, it is also measured in comparison with the Sun, but I felt the need to have it shown in it's full, bright (pun intended) glory.\n A lot can be found using a star's luminosity, such as it's temperature, habitable zone, and more.",120)
            printInfo("Star Radius: \n The radius of the star, or how large it is. Calculated with mass.\n Stars range greatly in radius, or size, so it is important to know the radius of a star. \n ",210)
            printInfo("Star Temperature: \n How bright the star is, in Kelvin. \n Kelvin is commonly used in Astronomy and other sciences due to the fact that 0K is absolute zero, or the lowest possible temperature something can be, making it easy to calculate certain things.",260)
            printInfo("Spectral Type: \n Most stars are classified under the following letters: O, B, A, F, G, K, and M \n Each letter is subdivided with a number, with 0 being the hottest and 9 being the coolest (ex. A0, K9). \n O-class stars are the hottest, being over 33,000K, with a mass greater than 16x the sun. \n These stars tend to be light blue in color. \n The coolest stars are M-class, being orange-red, and are less than half the mass of the Sun. \n Our sun is G-class, and is yellow or yellow-white.",340)
            printInfo("Lifetime: \n A star's lifetime is dependent on it's mass, as it burns hydrogen to fuel it's fire, and the larger the star, the more pressure on the core, resulting in more hydrogen getting burned, which shorten's its lifespan. \n When stars have minimal mass, it doesn't glow as much since there isn't a lot of pressure on its core, so less hydrogen is fused into helium.",470)
            printInfo("Habitable Zone: \n A star's habitable zone is proportional to its luminosity, as the brighter a star burns, the more heat it will emit, and therefore there will be a higher possibility for liquid water, since it won't be too hot that the water evaporates, or too cold so that it freezes. \n This isn't the only way to determine habitability, but it is a very accurate way to find out.",560)
            printInfo("Planet Orbit Radius: \n A planet's orbit radius is defined by the average distance from the planet to the star. \n In actuality, a planet's orbit is an ellipse rather than a circle, and its velocity changes throughout the orbit. \n A planet's orbit radius can be used to find Period and Temperature, which is defined later.",650)
            printInfo("Planet Period: \n A planet's period is defined by the amount of time it takes (in this case, measured in years) to orbit around its star. \n This period is important to know because if a planet was in a habitable zone, a period that was too large could meant that the planet actually isn't habitable, since there's a chance that it rotates too slowly, so if the planet were at a tilt, in such a way as the Earth, season would be too long, and certain parts of the planet would be abnormally hot or abnormally cold, depending on the seasons.",740)
            printInfo("Planet Temperature: \n A planet's temperature is the average temperature of the planet as it orbits around it's star. This is dependent on planet albedo, which is not possible to find using just orbit radius, so instead I present the temperature as a range. That is why it presents Earth's temperature as a range from 10 million to -200 degrees Celsius. \n Albedo can be found using the amount of light a planet reflects from the sun, but that sadly is not possible with the information required by my project.",860)
            printInfo("Stefan-Boltzmann Constant: \n The Stefan-Boltzmann Constant is used in the Stefan-Boltzmann Law, which says that an ideal emitter (such as a star) has a proportionality of M = s * T^4, M being mass, s being the Stefan-Boltzmann Constant, and T being Temperature.",990)
        end
    end

    for i,b in ipairs(buttons) do
        b:draw()
        if love.mouse.isDown(1) and collision("point",mouse,b) then
            b:press()
        end
    end
    love.graphics.setColor(1,1,1)
    love.graphics.circle("line",mouse.x, mouse.y,5)
end

function printInfo(s,x)
    love.graphics.printf(s,0,camy+x,window.width/1.25,"left",0,1.1)
end
function drawPlanet()
    local time = 8
    planet.period = math.sqrt(planet.orbitradius^3 / (star.mass))
    local ang = ((love.timer.getTime()) / (planet.period * time)) * (2*math.pi)
    local x = window.width/2 + math.cos(ang) * (planet.orbitradius*scale)
    local y = window.height/2 + math.sin(ang) * (planet.orbitradius*scale)
    love.graphics.circle("fill",x + camx,y + camy,5)
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
