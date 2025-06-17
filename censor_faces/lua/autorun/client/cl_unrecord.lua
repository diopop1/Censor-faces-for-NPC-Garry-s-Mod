-- Censor Faces for NPCs, Ragdolls, and Players with Glitch Effect
if CLIENT then
    -- Создаем клиентские переменные для управления эффектами
    local censor_enabled = CreateClientConVar("pp_censor_faces", "0", true, false)
    local censor_size = CreateClientConVar("pp_censor_faces_size", "64", true, false)
    local censor_effect = CreateClientConVar("pp_censor_faces_effect", "mosaic", true, false)
    local censor_regdoll_blur = CreateClientConVar("pp_censor_regdoll_blur", "0", true, false)
    local blur_enabled = CreateClientConVar("pp_blur_enabled", "0", true, false)
    local blur_size_convar = CreateClientConVar("pp_censor_faces_blur_size", "5", true, false)
    local filter_allied_npcs = CreateClientConVar("pp_censor_faces_allied_npcs", "0", true, false)
    local censor_players_enabled = CreateClientConVar("pp_censor_players", "1", true, false)  -- Для теста включаем цензуру игроков
    local censor_npc_enabled = CreateClientConVar("pp_censor_npc", "1", true, false)  -- Работа с NPC
    local new_size_handler = CreateClientConVar("pp_new_size_handler", "1", true, false)  -- Новый обработчик размеров цензуры
    local censor_faces_only = CreateClientConVar("pp_censor_faces_only", "0", true, false)  -- Новый переключатель для цензуры только лиц

    list.Set("PostProcess", "Censor Faces", {
        icon = "materials/gui/postprocess/censor_faces.jpg",
        convar = "pp_censor_faces",
        category = "#shaders_pp",
        cpanel = function(CPanel)
            local params = {
                Options = {},
                CVars = {},
                MenuButton = "1",
                Folder = "censor_faces"
            }

            params.Options["#preset.default"] = {
                pp_censor_faces_size = "64",
                pp_censor_faces_effect = "mosaic"
            }

            params.CVars = table.GetKeys(params.Options["#preset.default"])
            CPanel:AddControl("ComboBox", params)

            CPanel:AddControl("CheckBox", { 
                Label = "Enable Censor Faces", 
                Command = "pp_censor_faces" 
            })

            CPanel:AddControl("Label", {
                Text = "This addon is a modification of the original add-on Censored Faces of the Players from RG Studio. In this version, the method of handling censorship was changed, allowing it to be adapted for use on the faces of non-player characters (NPCs). Version 2.0"
            })

            CPanel:Help("")  -- Пустой отступ


            CPanel:AddControl("Label", {
                Text = "------- Objects Of Application -------"
            })


            CPanel:AddControl("CheckBox", { 
                Label = "Apply Blur to Ragdolls", 
                Command = "pp_censor_regdoll_blur" 
            })

            CPanel:AddControl("CheckBox", { 
                Label = "Enable Censor for Players", 
                Command = "pp_censor_players" 
            })

            CPanel:AddControl("CheckBox", { 
                Label = "Enable Censor for NPC", 
                Command = "pp_censor_npc" 
            })


            CPanel:AddControl("Label", {
                Text = "------- Additional and Experimental Settings -------"
            })


            CPanel:AddControl("CheckBox", { 
                Label = "New Size Handler", 
                Command = "pp_new_size_handler" 
            })

            -- Фильтр по врагам
            CPanel:AddControl("CheckBox", { 
                Label = "Filter Allied NPCs Only", 
                Command = "pp_censor_faces_allied_npcs" 
    
            })

            CPanel:AddControl("CheckBox", { 
                Label = "Censorship of faces only", 
                Command = "pp_censor_faces_only" 
            })

            
            CPanel:AddControl("Label", {
                Text = "------- Effect Settings -------"
            })


            CPanel:AddControl("ComboBox", {
                Label = "Censor Effect",
                Command = "pp_censor_faces_effect",
                Options = {
                    ["Mosaic"] = { pp_censor_faces_effect = "mosaic" },
                    ["Black Square"] = { pp_censor_faces_effect = "square" },
                    ["White Square"] = { pp_censor_faces_effect = "white Square" },
                    ["Glitch"] = { pp_censor_faces_effect = "glitch" }
                }
            })

            -- Кнопка для включения/отключения ползунка
            CPanel:AddControl("CheckBox", { 
                Label = "Enable Blur Size Slider", 
                Command = "pp_blur_enabled" 
            })

            -- Ползунок для размера блюра
            CPanel:AddControl("Slider", {
                Label = "Blur Size",
                Command = "pp_censor_faces_blur_size",
                Type = "Float",
                Min = "0",
                Max = "10",
                Description = "Adjust the size of the blur effect."
            })

        end
    })

    local dscale = ScrH() / 8
    local tex = GetRenderTarget("Unrecord_CensorFaces_RT_"..dscale, dscale * ScrW() / ScrH(), dscale)
    local mat = CreateMaterial("Unrecord_CensorFaces_RT"..dscale, "UnlitGeneric", {
        ["$basetexture"] = tex:GetName()
    })

    local blurMaterial = Material("pp/blurscreen")

    -- Список классов врагов
    local enemy_classes = {
        "npc_combine_s", "npc_combine_camera", "npc_combinegunship",
        "npc_metropolice", "npc_zombie", "npc_fastzombie",
        "npc_poisonzombie", "npc_antlion", "npc_antlion_worker",
        "npc_antlionguard", "npc_strider", "npc_turret_floor", "npc_turret_ceiling",
        "npc_turret_ground", "npc_manhack", "npc_rollermine"
    }

    local function isEnemyNPC(npc)
        local class = npc:GetClass()
        for _, enemy_class in ipairs(enemy_classes) do
            if class == enemy_class then
                return true
            end
        end
        return false
    end

    -- Перемещаем функцию за пределы хука, в раздел CLIENT
    local function IsEntityCensored(entity)
        -- Получаем список сущностей, которые не нужно цензурировать
        if _G.GetListExceptions then
            local ListExceptions = _G.GetListExceptions()

            -- Проверка NPC
            if entity:IsNPC() then
                if ListExceptions and ListExceptions[entity:EntIndex()] then
                    return false -- Не цензурить, если есть в списке
                end
                return true -- Цензурить всех остальных NPC
            end

            -- Проверка игроков
            if entity:IsPlayer() then
                if ListExceptions and ListExceptions[entity:EntIndex()] then
                    return false -- Не цензурить, если игрок в списке исключений
                end
                return true -- Цензурить всех остальных игроков
            end

            -- Проверка рэгдолов
            if entity:IsRagdoll() then
                if ListExceptions and ListExceptions[entity:EntIndex()] then
                    return false -- Не цензурить, если рэгдол в списке исключений
                end
                return true -- Цензурить все остальные рэгдолы
            end

            -- Для остальных сущностей используем старую логику
            return ListExceptions and ListExceptions[entity:EntIndex()] ~= nil
        end

        return false -- По умолчанию не цензурить, если список недоступен
    end

    -- Определение функции DrawCensorEffect перед её использованием
    local function DrawCensorEffect(entity, is_player, is_local_player, effect_type, censor_size, blur_size, rt_tex, use_new_size_handler, censor_faces_only)
        -- Если текстура не передана, используем нашу текстуру по умолчанию
        local useTexture = rt_tex or tex
        cam.Start2D()

        -- Получаем положение глаз/головы
        local attachment = entity:LookupAttachment("eyes")
        if attachment == 0 then
            attachment = entity:LookupAttachment("head") -- пробуем получить attachment головы
            if attachment == 0 then
                cam.End2D()
                return
            end
        end
                            
        local angpos = entity:GetAttachment(attachment)
        if not angpos then
            -- Используем позицию глаз для игроков как запасной вариант
            if is_player then
                angpos = {
                    Pos = entity:EyePos(),
                    Ang = entity:EyeAngles()
                }
            else
                cam.End2D()
                return
            end
        end
        
        local pos, eye_angles = angpos.Pos, angpos.Ang
        local data2D = pos:ToScreen()
        if not data2D.visible then
            cam.End2D()
            return
        end
        
        -- Трассировка для проверки, что нет объектов между камерой и головой
        -- На эту улучшенную версию:
        -- Трассировка для проверки, что нет объектов между камерой и головой
        if not is_local_player then
            local ply = LocalPlayer()
            
            -- Проверяем, находится ли игрок в транспорте
            local playerVehicle = ply:GetVehicle()
            local isInVehicle = IsValid(playerVehicle)
            
            local tr = util.TraceLine({
                start = ply:EyePos(),
                endpos = pos,
                filter = function(ent) 
                    -- Базовые исключения
                    if ent == entity or ent == ply then
                        return false
                    end
                    
                    -- Если в транспорте, исключаем сам транспорт
                    if isInVehicle and ent == playerVehicle then
                        return false
                    end
                    
                    -- Исключаем стекла и прозрачные материалы
                    local material = ent:GetMaterial()
                    if material then
                        local matLower = material:lower()
                        if string.find(matLower, "glass") or 
                        string.find(matLower, "window") or 
                        string.find(matLower, "transparent") then
                            return false
                        end
                    end
                    
                    -- Можно добавить проверку на конкретные классы транспорта
                    local class = ent:GetClass()
                    if string.find(class, "prop_vehicle") or 
                    string.find(class, "vehicle") then
                        -- Если это транспорт и игрок в нем, не учитываем
                        if isInVehicle and ent == playerVehicle then
                            return false
                        end
                    end
                    
                    return true
                end
            })
                                
            if tr.Hit then
                cam.End2D()
                return
            end
        end

        -- НОВАЯ ФУНКЦИОНАЛЬНОСТЬ: Проверка видимости лица
        if censor_faces_only and censor_faces_only == 1 then
            local localPlayerPos = LocalPlayer():EyePos()
            local localPlayerAngles = LocalPlayer():EyeAngles()
            local localPlayerForward = localPlayerAngles:Forward()
            
            -- Получаем направление взгляда сущности (куда смотрит лицо)
            local entityFaceDirection
            if is_player then
                entityFaceDirection = entity:EyeAngles():Forward()
            else
                -- Для NPC используем направление attachment'а глаз или головы
                if angpos and angpos.Ang then
                    entityFaceDirection = angpos.Ang:Forward()
                else
                    -- Запасной вариант - используем направление самой сущности
                    entityFaceDirection = entity:GetAngles():Forward()
                end
            end
            
            -- Вычисляем вектор от игрока к сущности
            local toEntity = (pos - localPlayerPos):GetNormalized()
            
            -- Проверяем угол между направлением лица сущности и направлением от игрока к сущности
            -- Если dot product отрицательный, значит лицо повернуто к нам
            -- Если положительный, значит мы видим затылок
            local faceDot = entityFaceDirection:Dot(toEntity)
            
            -- Если dot product > 0.3, значит мы видим больше затылок чем лицо
            if faceDot > 0.3 then
                cam.End2D()
                return
            end
        end

        if not is_player then
            -- Проверьте, есть ли хитбокс для головы
            if not entity.unrec_head_set then
                local numHitBoxSets = entity:GetHitboxSetCount()
                local set, bone = 0, 0
                for hboxset = 0, numHitBoxSets - 1 do
                    local numHitBoxes = entity:GetHitBoxCount(hboxset)
                    for hitbox = 0, numHitBoxes - 1 do
                        if entity:GetBoneName(entity:GetHitBoxBone(hitbox, hboxset)) == "ValveBiped.Bip01_Head1" then
                            set = hboxset
                            bone = hitbox
                            break
                        end
                    end
                end
                entity.unrec_head_set, entity.unrec_head_bone = set, bone
            end
        
            -- Убедитесь, что хитбокс был найден
            if not entity.unrec_head_set or not entity.unrec_head_bone then
                -- Выход, если не найден хитбокс
                cam.End2D()
                return
            end
        
            -- Теперь безопасно получаем границы хитбокса
            local mins, maxs = entity:GetHitBoxBounds(entity.unrec_head_bone, entity.unrec_head_set)
            if not mins or not maxs then
                -- Если хитбокс не был найден, выходим
                cam.End2D()
                return
            end
        end
        
                            
        local distance = entity:EyePos():Distance(LocalPlayer():EyePos())
        
        -- Определение центра лица
        local size
        local faceCenter

        if is_player then
            local headBone = entity:LookupBone("ValveBiped.Bip01_Head1")
            if headBone then
                faceCenter = entity:GetBonePosition(headBone)
            else
                faceCenter = entity:EyePos()  -- запасной вариант
            end
        else
            local size_handler = use_new_size_handler -- Используем параметр вместо ConVar напрямую
            local mins, maxs = entity:GetHitBoxBounds(entity.unrec_head_bone, entity.unrec_head_set)

            if not mins or not maxs then
                cam.End2D()
                return
            end
        
            mins = mins + entity:GetPos()
            maxs = maxs + entity:GetPos()
            faceCenter = (mins + maxs) * 0.5
        
            cam.Start3D(faceCenter + entity:EyeAngles():Forward() * 160, (-entity:EyeAngles():Forward()):Angle())
                local mins_toscreen, maxs_toscreen = mins:ToScreen(), maxs:ToScreen()
            cam.End3D()
        
            local maxxy = {
                x = math.max(maxs_toscreen.x, mins_toscreen.x),
                y = math.max(maxs_toscreen.y, mins_toscreen.y)
            }

            local minxy = {
                x = math.min(maxs_toscreen.x, mins_toscreen.x),
                y = math.min(mins_toscreen.y, maxs_toscreen.y)
            }
        
            if size_handler then
                local boxSize = maxs - mins
                local actualSize = math.max(boxSize.x, boxSize.y, boxSize.z)

                -- Получаем текущий FOV
                local currentFOV = LocalPlayer():GetFOV()
                local defaultFOV = 100 -- стандартный FOV в Source Engine (Начальное значение для работы currentFOV)

                -- Коэффициент для компенсации FOV
                local fovScale = defaultFOV / currentFOV

                -- Получаем разрешение экрана
                local scrW, scrH = ScrW(), ScrH()

                -- Базовое соотношение сторон (обычно 16:9 или 4:3)
                local baseAspectRatio = 16/9
                local currentAspectRatio = scrW / scrH

                -- Коэффициент для компенсации соотношения сторон
                local aspectScale = currentAspectRatio / baseAspectRatio

                -- Применяем все коэффициенты
                size = actualSize * (1 / distance) * (scrH / 8) * blur_size * 2 * fovScale * aspectScale
            else
                local xdiff, ydiff = math.abs(maxxy.x - minxy.x), math.abs(maxxy.y - minxy.y)
                size = math.max(xdiff, ydiff) * (1 / distance) * (ScrH() / 8) * blur_size / 2
            end
        end

        -- Для игроков используем фиксированный размер, масштабированный по дистанции
        if is_player then
            local size_handler = use_new_size_handler -- Используем параметр вместо ConVar напрямую
            if size_handler then
                local defaultFOV = 90
                local currentFOV = LocalPlayer():GetFOV()
                local fovFactor = defaultFOV / currentFOV
                local distanceFactor = 1 / math.max(distance, 10) * (30)
                size = censor_size * distanceFactor * blur_size * fovFactor
            else
                local distanceFactor = 1 / math.max(distance, 10) * (30)
                size = censor_size * distanceFactor * blur_size
            end
        end
        
        
        -- Дополнительные факторы искажения
        local centerX, centerY = ScrW() * 0.5, ScrH() * 0.5
        local dx, dy = data2D.x - centerX, data2D.y - centerY
        local distanceFromCenter = math.sqrt(dx * dx + dy * dy)
        local maxDistance = math.sqrt(centerX * centerX + centerY * centerY)
        local distortionFactorCenter = 1 + (distanceFromCenter / maxDistance)
        
        local eyePos = LocalPlayer():EyePos()
        local toObject = (faceCenter - eyePos):GetNormalized()
        local angleFactor = math.Clamp(EyeAngles():Forward():Dot(toObject), 0, 1)
        local distortionFactorAngle = 2 - angleFactor
        
        size = size * distortionFactorCenter * distortionFactorAngle
        
        -- Применение выбранного эффекта
        if effect_type == "square" then
            draw.RoundedBox(0, data2D.x - size, data2D.y - size, size * 2, size * 2, Color(0, 0, 0))
        elseif effect_type == "mosaic" then
            render.SetStencilWriteMask(0xFF)
            render.SetStencilTestMask(0xFF)
            render.SetStencilReferenceValue(1)
            render.SetStencilPassOperation(STENCIL_KEEP)
            render.SetStencilZFailOperation(STENCIL_KEEP)
            render.ClearStencil()
            render.SetStencilCompareFunction(STENCIL_NEVER)
            render.SetStencilFailOperation(STENCIL_REPLACE)
            render.SetStencilEnable(true)
                draw.RoundedBox(0, data2D.x - size, data2D.y - size, size * 2, size * 2, Color(0, 0, 0))
                render.SetStencilCompareFunction(STENCIL_EQUAL)
                render.SetStencilFailOperation(STENCIL_REPLACE)
                render.PushFilterMin(1)
                render.PushFilterMag(1)
                render.DrawTextureToScreen(useTexture)
                render.PopFilterMin()
                render.PopFilterMag()
            render.SetStencilEnable(false)
        elseif effect_type == "white Square" then
            draw.RoundedBox(0, data2D.x - size, data2D.y - size, size * 2, size * 2, Color(255, 255, 255))
        elseif effect_type == "glitch" then
            local glitch_size = size * 0.8
            local glitch_count = math.ceil(85)
        
            -- Основной глитч эффект
            for i = 1, glitch_count do
                local offsetX = math.random(-glitch_size, glitch_size)
                local offsetY = math.random(-glitch_size, glitch_size)
                local glitch_rect_width = math.random(size * 0.2, size * 0.5)
                local glitch_rect_height = math.random(size * 0.2, size * 0.5)
                local random_color = Color(math.random(0, 255), math.random(0, 255), math.random(0, 255), math.random(0, 255))
                draw.RoundedBox(0, data2D.x + offsetX, data2D.y + offsetY, glitch_rect_width, glitch_rect_height, random_color)
            end
        
            -- Добавление дергания
            local current_time = CurTime()
            local time_factor = (current_time % 1)
            local offset_factor = math.sin(time_factor * 2 * math.pi) * glitch_size * 0.05
        
            for i = 1, glitch_count do
                local offsetX = math.random(-glitch_size, glitch_size) + offset_factor
                local offsetY = math.random(-glitch_size, glitch_size) + offset_factor
                local glitch_rect_width = math.random(size * 0.2, size * 0.5)
                local glitch_rect_height = math.random(size * 0.2, size * 0.5)
                local random_color = Color(math.random(0, 255), math.random(0, 255), math.random(0, 255), math.random(50, 150))
                draw.RoundedBox(0, data2D.x + offsetX, data2D.y + offsetY, glitch_rect_width, glitch_rect_height, random_color)
            end
        end
        cam.End2D()
    end   
    
    -- Добавляем функцию в глобальный контекст
    _G.DrawCensorEffect = DrawCensorEffect
                     
    hook.Add("RenderScreenspaceEffects", "Unrecord_CensorFaces_PostProcess", function()
        if not censor_enabled:GetBool() then return end
       
        -- Получаем параметры
        local effect_type = censor_effect:GetString()
        local apply_blur_to_regdolls = censor_regdoll_blur:GetBool()
        local blur_slider_enabled = blur_enabled:GetBool()
        local blur_size = blur_slider_enabled and blur_size_convar:GetFloat() or 1.15
        local filter_allied_npcs_enabled = filter_allied_npcs:GetBool()
        local should_censor_npc = censor_npc_enabled:GetBool()
        local should_censor_players = censor_players_enabled:GetBool()
        local use_new_size_handler = new_size_handler:GetBool()
        
        -- НОВАЯ ПЕРЕМЕННАЯ: Получаем значение censor_faces_only
        local censor_faces_only = censor_faces_only:GetInt() 
       
        -- Копируем рендер-таргет один раз для всех эффектов
        render.CopyRenderTargetToTexture(tex)
       
        -- Обработка всех сущностей: NPC, рэгдоллы и игроки
        for _, entity in ipairs(ents.GetAll()) do
            local is_npc = entity:IsNPC()
            local is_regdoll = entity:IsRagdoll()
            local is_player = entity:IsPlayer()
            local is_local_player = is_player and entity == LocalPlayer()
           
            -- Пропускаем локального игрока, если цензура отключена
            if is_local_player then continue end
            
            -- ГЛАВНОЕ ИСПРАВЛЕНИЕ: Проверка списка исключений
            -- Если сущность в списке исключений, пропускаем её
            if _G.GetListExceptions and _G.GetListExceptions()[entity:EntIndex()] then
                continue
            end
           
            -- Проверяем тип сущности и соответствующие настройки
            if is_player then
                -- Пропускаем игроков, если их цензура отключена
                if not should_censor_players then continue end
            elseif is_npc then
                -- Пропускаем NPC, если их цензура отключена или если фильтр врагов включен
                if not should_censor_npc or (filter_allied_npcs_enabled and isEnemyNPC(entity)) then continue end
            elseif is_regdoll then
                -- Пропускаем рэгдоллы, если цензура для них отключена
                if not apply_blur_to_regdolls then continue end
            else
                -- Пропускаем все остальные сущности
                continue
            end
           
            -- Теперь вызываем функцию для цензуры с новым параметром
            DrawCensorEffect(
                entity,
                is_player,
                is_local_player,
                effect_type,
                censor_size:GetFloat(),
                blur_size,
                tex,
                use_new_size_handler,
                censor_faces_only  -- НОВЫЙ ПАРАМЕТР
            )
        end
    end)
end

/*

Censor Faces - 2.1 Release Build

--------------
diopop1 - 2025
Build 2.1 | 2025.06.17 

*DrawCensorEffect UPDATE (new parameter censor_faces_only)
*Added new ConVar pp_censor_faces_only (0 - disabled, 1 - enabled)
*Fixed a problem with tracing in transport that caused the addon not to work in transport
*Fixed an issue that caused the New Size Handler to not work correctly with the ability to change the fov in the game, which led to incorrect calculations when using zoom (May not be fixed for players)
--------------


*/
