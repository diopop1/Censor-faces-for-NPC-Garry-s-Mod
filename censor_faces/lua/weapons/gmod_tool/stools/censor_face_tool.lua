-- В вашем файле инструмента:
TOOL.Category = "Censor Face Tool"
TOOL.Name = "#tool.censor_face_tool.name"
TOOL.ClientConVar["target_list"] = ""

-- Устанавливаем информацию о действии
TOOL.Information = {
    { name = "info", stage = 1 },
    { name = "left" },
    { name = "right" }
}


-- Сделайте targetList глобальным или доступным через _G
_G.CensorTargetList = _G.CensorTargetList or {}
local targetList = _G.CensorTargetList

if CLIENT then
    language.Add("tool.censor_face_tool.name", "Censor Face Tool")
    language.Add("tool.censor_face_tool.desc", "Add or remove specific NPCs and players for censorship")
    language.Add("tool.censor_face_tool.left", "Add to exclusion list")
    language.Add("tool.censor_face_tool.right", "Remove from exclusion list")

    
    -- Добавить приемник сетевого сообщения на стороне клиента
    net.Receive("UpdateListExceptions", function()
        _G.CensorTargetList = net.ReadTable()
        targetList = _G.CensorTargetList
    end)
    
    -- Сделать функцию GetListExceptions глобально доступной
    function GetListExceptions()
        return _G.CensorTargetList
    end
end

if SERVER then
    util.AddNetworkString("UpdateListExceptions")
end

-- Функция для добавления сущности в список исключений
local function AddToListExceptions(ply, ent)
    if not IsValid(ent) then return end
    if not ent:IsNPC() and not ent:IsPlayer() and not ent:IsRagdoll() then return end -- Регдолы
    local entID = ent:EntIndex()
    if not targetList[entID] then
        targetList[entID] = ent
        ply:ChatPrint("Entity added to the exclusion list: " .. tostring(ent))

        -- Отправить обновленный список всем игрокам
        if SERVER then
            net.Start("UpdateListExceptions")
            net.WriteTable(targetList)
            net.Broadcast()
        end
    else
        ply:ChatPrint("The entity is already in the exclusion list.")
    end
end

-- Функция для удаления сущности из списка исключений
local function RemoveFromListExceptions(ply, ent)
    if not IsValid(ent) then return end
    local entID = ent:EntIndex()
    if targetList[entID] then
        targetList[entID] = nil
        ply:ChatPrint("Entity removed from exclusion list: " .. tostring(ent))

        -- Отправить обновленный список всем игрокам
        if SERVER then
            net.Start("UpdateListExceptions")
            net.WriteTable(targetList)
            net.Broadcast()
        end
    else
        ply:ChatPrint("Entity not found in exclusion list.")
    end
end


-- Отправить данные клиенту при появлении игрока
if SERVER then
    hook.Add("PlayerInitialSpawn", "SyncListExceptions", function(ply)
        net.Start("UpdateListExceptions")
        net.WriteTable(targetList)
        net.Send(ply)
    end)
end

-- Левый клик - добавить в список
function TOOL:LeftClick(trace)
    if not IsValid(trace.Entity) then return false end
    if CLIENT then return true end
    AddToListExceptions(self:GetOwner(), trace.Entity)
    return true
end

-- Правый клик - удалить из списка
function TOOL:RightClick(trace)
    if not IsValid(trace.Entity) then return false end
    if CLIENT then return true end
    RemoveFromListExceptions(self:GetOwner(), trace.Entity)
    return true
end

-- Отображение информации на экране
function TOOL:DrawHUD()
    if CLIENT then
        for entID, ent in pairs(targetList) do
            if IsValid(ent) then
                local pos = ent:LocalToWorld(ent:OBBCenter()):ToScreen()
                draw.SimpleText("Not censored", "DermaDefault", pos.x, pos.y, Color(255, 255, 255), TEXT_ALIGN_CENTER)
            end
        end
    end
end

-- Убедитесь, что это находится в начале вашего файла инструмента
if CLIENT then
    -- Создать глобальную функцию для доступа к списку
    _G.GetListExceptions = function()
        return _G.CensorTargetList or {}
    end
end

-- Сделать targetList глобальным
_G.CensorTargetList = _G.CensorTargetList or {}
local targetList = _G.CensorTargetList

-- Очистка сущностей при удалении
hook.Add("EntityRemoved", "CleanupListExceptions", function(ent)
    local entID = ent:EntIndex()
    if targetList[entID] then
        targetList[entID] = nil
        
        -- Обновить клиентов после удаления сущности
        if SERVER then
            net.Start("UpdateListExceptions")
            net.WriteTable(targetList)
            net.Broadcast()
        end
    end
end)