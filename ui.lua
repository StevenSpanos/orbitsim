UI = Object.extend(Object)

function UI:new(x,y,w,h,id)
    self.x      = x
    self.y      = y
    self.width  = w
    self.height = h
    self.id     = id
    self.subID = nil
    if id == "textbox" then
        self.content = ""
        self.selected = false
    end

    if id == "infobox" then
        self.expanded = false
    end

    if id == "button" then
        table.insert(buttons,self)
    end
    self.hidden = false
end

function UI:visibility()
    self.hidden = not self.hidden
end

function UI:draw()
    if self.id == "button" then
        love.graphics.rectangle("line", self.x,self.y,self.width,self.height)

        if self.subID ~= nil then
            if self.subID == "add" then
                love.graphics.rectangle("fill",self.x+self.width/2-3,self.y + 6,6,self.height-12)
                love.graphics.rectangle("fill",self.x+6,self.y+self.height/2-3,self.width-12,6)
            end
        end
    end
end

function UI:press()
    if self.subID == "add" then
        textbox.hidden = false
    end
end

