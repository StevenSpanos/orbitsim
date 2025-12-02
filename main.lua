function love.load()
    window = {}
    window.width = love.graphics.getWidth()
    window.height = love.graphics.getHeight()

    textbox = {}
    textbox.width = 150
    textbox.height = 25
    textbox.x = window.width / 2 - textbox.width / 2
    textbox.y = window.height / 2 - textbox.height / 2
    textbox.selected = false
    textbox.content = ""

    mouse = {}
    mouse.x = love.mouse.getX()
    mouse.y = love.mouse.getY()

    star = {}
    star.mass = 0

    planet = {}
    planet.radius = 0
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
            textbox.content = string.sub(textbox.content, 1, -2)
        end
        if key == "return" then
            star.mass = tonumber(textbox.content)
            textbox.content = ""
        end
    end
end

function love.draw()
    love.graphics.print("Enter Star Mass (Solar Masses):",textbox.x, textbox.y-textbox.height)
    love.graphics.rectangle("line",textbox.x, textbox.y, textbox.width, textbox.height)
    love.graphics.print(textbox.content, textbox.x, textbox.y,0,1.5)
    love.graphics.circle("line",mouse.x, mouse.y,5)
end

function love.textinput(t)
    if textbox.selected then
        if t:match("%d") then
        textbox.content = textbox.content .. t
        end
    end
end
function collision(string, obj1, obj2)
    if string == "point" then
        return (obj1.x >= obj2.x) and ((obj1.x - obj2.width) <= obj2.x) and (obj1.y >= obj2.y) and ((obj1.y - obj2.height) <= obj2.y)
    end
end