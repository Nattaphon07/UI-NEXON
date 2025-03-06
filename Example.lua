-- NEXON UI Library
-- Created with advanced styling and full functionality

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TextService = game:GetService("TextService")

local Player = Players.LocalPlayer

-- Constants
local FONT = Enum.Font.Gotham
local TEXT_SIZE = 14
local HEADER_SIZE = 18
local TITLE_SIZE = 24
local CORNER_RADIUS = 6
local TWEEN_TIME = 0.2
local ELEMENT_HEIGHT = 36
local ACCENT_COLOR = Color3.fromRGB(255, 0, 128) -- Hot pink accent
local SHADOW_COLOR = Color3.fromRGB(0, 0, 0)

-- Main Library
local NexonUI = {
    Windows = {},
    Flags = {},
    Theme = {
        Background = Color3.fromRGB(25, 25, 25),
        Card = Color3.fromRGB(30, 30, 30),
        TopBar = Color3.fromRGB(35, 35, 35),
        Section = Color3.fromRGB(40, 40, 40),
        Text = Color3.fromRGB(255, 255, 255),
        SubText = Color3.fromRGB(200, 200, 200),
        Accent = ACCENT_COLOR,
        LightAccent = Color3.fromRGB(255, 100, 175),
        Error = Color3.fromRGB(255, 68, 68),
        Success = Color3.fromRGB(68, 255, 135),
        Warning = Color3.fromRGB(255, 184, 48)
    },
    Initialized = false
}

-- Utility Functions
local Utility = {}

function Utility:Create(class, properties)
    local instance = Instance.new(class)
    
    for prop, value in pairs(properties) do
        if prop ~= "Parent" then
            instance[prop] = value
        end
    end
    
    if properties.Parent then
        instance.Parent = properties.Parent
    end
    
    return instance
end

function Utility:Tween(instance, properties, time, style, direction, callback)
    time = time or TWEEN_TIME
    style = style or Enum.EasingStyle.Quart
    direction = direction or Enum.EasingDirection.Out
    
    local tween = TweenService:Create(
        instance,
        TweenInfo.new(time, style, direction),
        properties
    )
    
    tween:Play()
    
    if callback then
        tween.Completed:Connect(callback)
    end
    
    return tween
end

function Utility:MakeDraggable(frame, handle)
    local dragging = false
    local dragInput, mousePos, framePos
    
    handle = handle or frame
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            Utility:Tween(frame, {
                Position = UDim2.new(
                    framePos.X.Scale, 
                    framePos.X.Offset + delta.X,
                    framePos.Y.Scale,
                    framePos.Y.Offset + delta.Y
                )
            }, 0.05)
        end
    end)
end

function Utility:CreateShadow(parent, elevation)
    elevation = elevation or 1
    local size = 8 * elevation
    
    local shadow = Utility:Create("ImageLabel", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, size, 1, size),
        Image = "rbxassetid://7709956454",
        ImageColor3 = SHADOW_COLOR,
        ImageTransparency = 0.2,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(15, 15, 175, 175),
        SliceScale = 1,
        ZIndex = 0,
        Parent = parent
    })
    
    return shadow
end

function Utility:Ripple(button, centered)
    button.ClipsDescendants = true
    
    button.MouseButton1Down:Connect(function(x, y)
        local ripple = Utility:Create("Frame", {
            Name = "Ripple",
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.7,
            BorderSizePixel = 0,
            Position = centered and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0, x - button.AbsolutePosition.X, 0, y - button.AbsolutePosition.Y),
            Size = UDim2.new(0, 0, 0, 0),
            ZIndex = 10,
            Parent = button
        })
        
        Utility:Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = ripple
        })
        
        local size = centered and button.AbsoluteSize.X or math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
        
        Utility:Tween(ripple, {
            Size = UDim2.new(0, size, 0, size),
            BackgroundTransparency = 1
        }, 0.5)
        
        wait(0.5)
        ripple:Destroy()
    end)
end

function Utility:SmoothScroll(scrollFrame, speed)
    speed = speed or 14
    local goal = scrollFrame.CanvasPosition
    
    RunService.RenderStepped:Connect(function()
        scrollFrame.CanvasPosition = scrollFrame.CanvasPosition:Lerp(goal, speed / 100)
    end)
    
    scrollFrame.Changed:Connect(function(prop)
        if prop == "CanvasPosition" and scrollFrame.CanvasPosition ~= goal then
            goal = scrollFrame.CanvasPosition
        end
    end)
    
    return goal
end

-- Library Initialization
function NexonUI:Init()
    if self.Initialized then return self end
    
    self.ScreenGui = Utility:Create("ScreenGui", {
        Name = "NexonUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })
    
    -- Handle proper parenting for the GUI
    if RunService:IsStudio() then
        self.ScreenGui.Parent = Player:WaitForChild("PlayerGui")
    else
        pcall(function()
            self.ScreenGui.Parent = CoreGui
        end)
        
        if not self.ScreenGui.Parent then
            self.ScreenGui.Parent = Player:WaitForChild("PlayerGui")
        end
    end
    
    -- Create Notification Container
    self.NotificationHolder = Utility:Create("Frame", {
        Name = "NotificationHolder",
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -20, 0, 20),
        Size = UDim2.new(0, 300, 1, -40),
        ZIndex = 10,
        Parent = self.ScreenGui
    })
    
    Utility:Create("UIListLayout", {
        Padding = UDim.new(0, 10),
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Parent = self.NotificationHolder
    })
    
    self.Initialized = true
    return self
end

-- Create Window
function NexonUI:CreateWindow(options)
    self:Init()
    
    options = options or {}
    options.Title = options.Title or "NEXON"
    options.Size = options.Size or UDim2.new(0, 680, 0, 500)
    options.Position = options.Position or UDim2.new(0.5, -340, 0.5, -250)
    
    local window = {
        Tabs = {},
        ActiveTab = nil,
        TabCount = 0,
        Toggled = true
    }
    
    -- Create Main Frame
    window.Frame = Utility:Create("Frame", {
        Name = "WindowFrame",
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        Position = options.Position,
        Size = options.Size,
        Parent = self.ScreenGui
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, CORNER_RADIUS),
        Parent = window.Frame
    })
    
    -- Add Shadow
    Utility:CreateShadow(window.Frame, 2)
    
    -- Create Topbar
    window.TopBar = Utility:Create("Frame", {
        Name = "TopBar",
        BackgroundColor3 = self.Theme.TopBar,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 40),
        ZIndex = 2,
        Parent = window.Frame
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, CORNER_RADIUS),
        Parent = window.TopBar
    })
    
    -- Bottom frame to fix corner overlap
    local topBarFix = Utility:Create("Frame", {
        BackgroundColor3 = self.Theme.TopBar,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -CORNER_RADIUS),
        Size = UDim2.new(1, 0, 0, CORNER_RADIUS),
        Parent = window.TopBar
    })
    
    -- Logo/Title
    window.Title = Utility:Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(0, 200, 1, 0),
        Font = FONT,
        Text = options.Title,
        TextColor3 = self.Theme.Accent,
        TextSize = TITLE_SIZE,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = window.TopBar
    })
    
    -- Close Button
    window.CloseButton = Utility:Create("ImageButton", {
        Name = "CloseButton",
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -40, 0, 0),
        Size = UDim2.new(0, 40, 0, 40),
        Image = "rbxassetid://10734898835",
        ImageColor3 = self.Theme.Text,
        ImageTransparency = 0.2,
        Parent = window.TopBar
    })
    
    -- Minimize Button
    window.MinimizeButton = Utility:Create("ImageButton", {
        Name = "MinimizeButton",
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -80, 0, 0),
        Size = UDim2.new(0, 40, 0, 40),
        Image = "rbxassetid://10734950110",
        ImageColor3 = self.Theme.Text,
        ImageTransparency = 0.2,
        Parent = window.TopBar
    })
    
    -- Make window draggable by TopBar
    Utility:MakeDraggable(window.Frame, window.TopBar)
    
    -- Container for Tabs and Content
    window.Container = Utility:Create("Frame", {
        Name = "Container",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(1, 0, 1, -40),
        Parent = window.Frame
    })
    
    -- Tab Container (Sidebar)
    window.TabsFrame = Utility:Create("Frame", {
        Name = "TabsFrame",
        BackgroundColor3 = self.Theme.Card,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0, 10),
        Size = UDim2.new(0, 150, 1, -20),
        Parent = window.Container
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, CORNER_RADIUS),
        Parent = window.TabsFrame
    })
    
    -- Tab Buttons Container
    window.TabButtons = Utility:Create("ScrollingFrame", {
        Name = "TabButtons",
        Active = true,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 10),
        Size = UDim2.new(1, 0, 1, -20),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = window.TabsFrame
    })
    
    local tabsLayout = Utility:Create("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = window.TabButtons
    })
    
    Utility:Create("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = window.TabButtons
    })
    
    -- Update tab buttons canvas size when adding new tabs
    tabsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        window.TabButtons.CanvasSize = UDim2.new(0, 0, 0, tabsLayout.AbsoluteContentSize.Y + 20)
    end)
    
    -- Content Frame
    window.Content = Utility:Create("Frame", {
        Name = "Content",
        BackgroundColor3 = self.Theme.Card,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 170, 0, 10),
        Size = UDim2.new(1, -180, 1, -20),
        Parent = window.Container
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, CORNER_RADIUS),
        Parent = window.Content
    })
    
    -- Handle close button
    window.CloseButton.MouseButton1Click:Connect(function()
        Utility:Tween(window.Frame, {
            Size = UDim2.new(0, window.Frame.AbsoluteSize.X, 0, 0),
            Position = UDim2.new(
                window.Frame.Position.X.Scale,
                window.Frame.Position.X.Offset,
                window.Frame.Position.Y.Scale,
                window.Frame.Position.Y.Offset + window.Frame.AbsoluteSize.Y/2
            )
        }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In, function()
            window.Frame:Destroy()
        end)
    end)
    
    -- Handle minimize button
    local minimized = false
    window.MinimizeButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            window.MinimizeButton.Image = "rbxassetid://10734950964" -- Restore icon
            Utility:Tween(window.Container, {Size = UDim2.new(1, 0, 0, 0)}, 0.3)
            Utility:Tween(window.Frame, {Size = UDim2.new(0, window.Frame.AbsoluteSize.X, 0, 40)}, 0.3)
        else
            window.MinimizeButton.Image = "rbxassetid://10734950110" -- Minimize icon
            Utility:Tween(window.Frame, {Size = options.Size}, 0.3)
            Utility:Tween(window.Container, {Size = UDim2.new(1, 0, 1, -40)}, 0.3)
        end
    end)
    
    -- Add hover effects to buttons
    local function addButtonEffects(button)
        button.MouseEnter:Connect(function()
            Utility:Tween(button, {ImageTransparency = 0}, 0.2)
        end)
        
        button.MouseLeave:Connect(function()
            Utility:Tween(button, {ImageTransparency = 0.2}, 0.2)
        end)
    end
    
    addButtonEffects(window.CloseButton)
    addButtonEffects(window.MinimizeButton)
    
    -- Tab functionality
    function window:AddTab(name, icon)
        local tab = {
            Name = name,
            Sections = {},
            Elements = {}
        }
        
        window.TabCount = window.TabCount + 1
        local isFirstTab = window.TabCount == 1
        
        -- Create tab button
        tab.Button = Utility:Create("TextButton", {
            Name = name .. "Tab",
            BackgroundColor3 = isFirstTab and NexonUI.Theme.Accent or NexonUI.Theme.Card,
            BackgroundTransparency = isFirstTab and 0.3 or 0.7,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 40),
            Font = FONT,
            Text = "  " .. name,
            TextColor3 = isFirstTab and NexonUI.Theme.Text or NexonUI.Theme.SubText,
            TextSize = TEXT_SIZE,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            LayoutOrder = window.TabCount,
            Parent = window.TabButtons
        })
        
        Utility:Create("UICorner", {
            CornerRadius = UDim.new(0, CORNER_RADIUS - 2),
            Parent = tab.Button
        })
        
        -- Add icon if specified
        if icon then
            local iconImage = Utility:Create("ImageLabel", {
                Name = "Icon",
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 8, 0.5, 0),
                Size = UDim2.new(0, 20, 0, 20),
                AnchorPoint = Vector2.new(0, 0.5),
                Image = icon,
                ImageColor3 = isFirstTab and NexonUI.Theme.Text or NexonUI.Theme.SubText,
                Parent = tab.Button
            })
            
            tab.Button.Text = "      " .. name
            tab.Icon = iconImage
        end
        
        -- Create tab content
        tab.Container = Utility:Create("ScrollingFrame", {
            Name = name .. "Container",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarImageColor3 = NexonUI.Theme.Accent,
            ScrollBarThickness = 3,
            Visible = isFirstTab,
            Parent = window.Content
        })
        
        -- Add padding
        Utility:Create("UIPadding", {
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            Parent = tab.Container
        })
        
        -- Create layout for sections and elements
        local tabLayout = Utility:Create("UIListLayout", {
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = tab.Container
        })
        
        -- Update canvas size when content changes
        tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tab.Container.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 20)
        end)
        
        -- Smooth scrolling
        Utility:SmoothScroll(tab.Container)
        
        -- Add ripple effect
        Utility:Ripple(tab.Button, true)
        
        -- Tab button hover effect
        tab.Button.MouseEnter:Connect(function()
            if tab.Button.BackgroundColor3 ~= NexonUI.Theme.Accent then
                Utility:Tween(tab.Button, {
                    BackgroundTransparency = 0.5,
                    TextColor3 = NexonUI.Theme.Text
                }, 0.2)
                
                if tab.Icon then
                    Utility:Tween(tab.Icon, {
                        ImageColor3 = NexonUI.Theme.Text
                    }, 0.2)
                end
            end
        end)
        
        tab.Button.MouseLeave:Connect(function()
            if tab.Button.BackgroundColor3 ~= NexonUI.Theme.Accent then
                Utility:Tween(tab.Button, {
                    BackgroundTransparency = 0.7,
                    TextColor3 = NexonUI.Theme.SubText
                }, 0.2)
                
                if tab.Icon then
                    Utility:Tween(tab.Icon, {
                        ImageColor3 = NexonUI.Theme.SubText
                    }, 0.2)
                end
            end
        end)
        
        -- Tab selection
        tab.Button.MouseButton1Click:Connect(function()
            window:SelectTab(name)
        end)
        
        -- Remember the active tab
        if isFirstTab then
            window.ActiveTab = name
        end
        
        -- Store tab in window
        window.Tabs[name] = tab
        
        -- Section creation function
        function tab:AddSection(sectionName)
            local section = {}
            
            -- Create section frame
            section.Frame = Utility:Create("Frame", {
                Name = sectionName .. "Section",
                BackgroundColor3 = NexonUI.Theme.Section,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 40), -- Initial height, expands with content
                Parent = tab.Container
            })
            
            Utility:Create("UICorner", {
                CornerRadius = UDim.new(0, CORNER_RADIUS - 2),
                Parent = section.Frame
            })
            
            -- Section title
            section.Title = Utility:Create("TextLabel", {
                Name = "Title",
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -24, 0, 30),
                Font = FONT,
                Text = sectionName,
                TextColor3 = NexonUI.Theme.SubText,
                TextSize = HEADER_SIZE,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = section.Frame
            })
            
            -- Section content container
            section.Container = Utility:Create("Frame", {
                Name = "Container",
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 30),
                Size = UDim2.new(1, -20, 0, 0), -- Will expand with content
                Parent = section.Frame
            })
            
            -- Create layout for elements
            local sectionLayout = Utility:Create("UIListLayout", {
                Padding = UDim.new(0, 8),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = section.Container
            })
            
            -- Resize section based on content
            sectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                section.Container.Size = UDim2.new(1, -20, 0, sectionLayout.AbsoluteContentSize.Y)
                section.Frame.Size = UDim2.new(1, 0, 0, sectionLayout.AbsoluteContentSize.Y + 40)
            end)
            
            -- Add label element
            function section:AddLabel(text)
                local label = {}
                
                label.Frame = Utility:Create("Frame", {
                    Name = "Label",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 20),
                    Parent = section.Container
                })
                
                label.Text = Utility:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Font = FONT,
                    Text = text,
                    TextColor3 = NexonUI.Theme.SubText,
                    TextSize = TEXT_SIZE,
                    TextWrapped = true,
                    Parent = label.Frame
                })
                
                function label:SetText(newText)
                    label.Text.Text = newText
                end
                
                return label
            end
            
            -- Add button element
            function section:AddButton(options)
                options = options or {}
                options.Text = options.Text or "Button"
                options.Callback = options.Callback or function() end
                
                local button = {}
                
                button.Frame = Utility:Create("Frame", {
                    Name = "Button",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, ELEMENT_HEIGHT),
                    Parent = section.Container
                })
                
                button.Button = Utility:Create("TextButton", {
                    BackgroundColor3 = NexonUI.Theme.Accent,
                    Size = UDim2.new(1, 0, 1, 0),
                    Font = FONT,
                    TextColor3 = NexonUI.Theme.Text,
                    Text = options.Text,
                    TextSize = TEXT_SIZE,
                    AutoButtonColor = false,
                    Parent = button.Frame
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(0, CORNER_RADIUS - 2),
                    Parent = button.Button
                })
                
                -- Add ripple effect
                Utility:Ripple(button.Button)
                
                -- Button callback
                button.Button.MouseButton1Click:Connect(function()
                    options.Callback()
                end)
                
                function button:SetText(newText)
                    button.Button.Text = newText
                end
                
                return button
            end
            
            -- Add toggle element
            function section:AddToggle(options)
                options = options or {}
                options.Text = options.Text or "Toggle"
                options.Default = options.Default or false
                options.Flag = options.Flag or nil
                options.Callback = options.Callback or function() end
                
                local toggle = {}
                toggle.Value = options.Default
                
                toggle.Frame = Utility:Create("Frame", {
                    Name = "Toggle",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, ELEMENT_HEIGHT),
                    Parent = section.Container
                })
                
                toggle.Label = Utility:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 0, 0, 0),
                    Size = UDim2.new(1, -60, 1, 0),
                    Font = FONT,
                    Text = options.Text,
                    TextColor3 = NexonUI.Theme.Text,
                    TextSize = TEXT_SIZE,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = toggle.Frame
                })
                
                toggle.Background = Utility:Create("Frame", {
                    Name = "Background",
                    BackgroundColor3 = toggle.Value and NexonUI.Theme.Accent or NexonUI.Theme.Card,
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, -50, 0.5, 0),
                    Size = UDim2.new(0, 40, 0, 20),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Parent = toggle.Frame
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = toggle.Background
                })
                
                toggle.Switch = Utility:Create("Frame", {
                    Name = "Switch",
                    BackgroundColor3 = NexonUI.Theme.Text,
                    BorderSizePixel = 0,
                    Position = toggle.Value and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
                    Size = UDim2.new(0, 16, 0, 16),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Parent = toggle.Background
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = toggle.Switch
                })
                
                -- Toggle the switch
                local function updateToggle()
                    toggle.Value = not toggle.Value
                    
                    Utility:Tween(toggle.Background, {
                        BackgroundColor3 = toggle.Value and NexonUI.Theme.Accent or NexonUI.Theme.Card
                    }, 0.2)
                    
                    Utility:Tween(toggle.Switch, {
                        Position = toggle.Value and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
                    }, 0.2)
                    
                    if options.Flag then
                        NexonUI.Flags[options.Flag] = toggle.Value
                    end
                    
                    options.Callback(toggle.Value)
                end
                
                -- Handle clicking anywhere on the toggle frame
                toggle.Frame.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        updateToggle()
                    end
                end)
                
                -- Add to flags if needed
                if options.Flag then
                    NexonUI.Flags[options.Flag] = toggle.Value
                end
                
                function toggle:SetValue(value)
                    if toggle.Value ~= value then
                        toggle.Value = not value -- Flip it so updateToggle flips it back
                        updateToggle()
                    end
                end
                
                return toggle
            end
            
            -- Add slider element
            function section:AddSlider(options)
                options = options or {}
                options.Text = options.Text or "Slider"
                options.Min = options.Min or 0
                options.Max = options.Max or 100
                options.Default = options.Default or options.Min
                options.Increment = options.Increment or 1
                options.Flag = options.Flag or nil
                options.Callback = options.Callback or function() end
                options.ValueDisplay = options.ValueDisplay ~= nil and options.ValueDisplay or true
                options.Suffix = options.Suffix or ""
                
                local slider = {}
                slider.Value = options.Default
                
                slider.Frame = Utility:Create("Frame", {
                    Name = "Slider",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, ELEMENT_HEIGHT + 15),
                    Parent = section.Container
                })
                
                slider.Label = Utility:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 0, 0, 0),
                    Size = UDim2.new(1, 0, 0, 20),
                    Font = FONT,
                    Text = options.Text,
                    TextColor3 = NexonUI.Theme.Text,
                    TextSize = TEXT_SIZE,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = slider.Frame
                })
                
                slider.Background = Utility:Create("Frame", {
                    Name = "Background",
                    BackgroundColor3 = NexonUI.Theme.Card,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 0, 25),
                    Size = UDim2.new(1, 0, 0, 10),
                    Parent = slider.Frame
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = slider.Background
                })
                
                slider.Fill = Utility:Create("Frame", {
                    Name = "Fill",
                    BackgroundColor3 = NexonUI.Theme.Accent,
                    BorderSizePixel = 0,
                    Size = UDim2.new((slider.Value - options.Min) / (options.Max - options.Min), 0, 1, 0),
                    Parent = slider.Background
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = slider.Fill
                })
                
                slider.Button = Utility:Create("TextButton", {
                    Name = "Button",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "",
                    Parent = slider.Background
                })
                
                if options.ValueDisplay then
                    slider.Value = Utility:Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(1, 0, 0, 0),
                        Size = UDim2.new(0, 50, 0, 20),
                        Font = FONT,
                        Text = tostring(slider.Value) .. options.Suffix,
                        TextColor3 = NexonUI.Theme.SubText,
                        TextSize = TEXT_SIZE,
                        TextXAlignment = Enum.TextXAlignment.Right,
                        AnchorPoint = Vector2.new(1, 0),
                        Parent = slider.Frame
                    })
                end
                
                -- Slider functionality
                local isDragging = false
                
                local function updateSlider(input)
                    local percent = math.clamp((input.Position.X - slider.Background.AbsolutePosition.X) / slider.Background.AbsoluteSize.X, 0, 1)
                    
                    local value = options.Min + ((options.Max - options.Min) * percent)
                    value = math.floor(value / options.Increment + 0.5) * options.Increment
                    value = math.clamp(value, options.Min, options.Max)
                    
                    if value ~= slider.Value then
                        slider.Value = value
                        
                        Utility:Tween(slider.Fill, {
                            Size = UDim2.new(percent, 0, 1, 0)
                        }, 0.1)
                        
                        if options.ValueDisplay then
                            slider.Value.Text = tostring(slider.Value) .. options.Suffix
                        end
                        
                        if options.Flag then
                            NexonUI.Flags[options.Flag] = slider.Value
                        end
                        
                        options.Callback(slider.Value)
                    end
                end
                
                slider.Button.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        isDragging = true
                        updateSlider(input)
                    end
                end)
                
                slider.Button.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        isDragging = false
                    end
                end)
                
                UserInputService.InputChanged:Connect(function(input)
                    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        updateSlider(input)
                    end
                end)
                
                -- Add to flags if needed
                if options.Flag then
                    NexonUI.Flags[options.Flag] = slider.Value
                end
                
                function slider:SetValue(value)
                    value = math.clamp(value, options.Min, options.Max)
                    slider.Value = value
                    
                    local percent = (value - options.Min) / (options.Max - options.Min)
                    
                    Utility:Tween(slider.Fill, {
                        Size = UDim2.new(percent, 0, 1, 0)
                    }, 0.1)
                    
                    if options.ValueDisplay then
                        slider.Value.Text = tostring(value) .. options.Suffix
                    end
                    
                    if options.Flag then
                        NexonUI.Flags[options.Flag] = value
                    end
                    
                    options.Callback(value)
                end
                
                return slider
            end
            
            -- Add Dropdown element
            function section:AddDropdown(options)
                options = options or {}
                options.Text = options.Text or "Dropdown"
                options.Default = options.Default or ""
                options.Items = options.Items or {}
                options.Flag = options.Flag or nil
                options.Callback = options.Callback or function() end
                options.MultiSelect = options.MultiSelect or false
                
                local dropdown = {}
                dropdown.Value = options.MultiSelect and {} or options.Default
                dropdown.Open = false
                
                dropdown.Frame = Utility:Create("Frame", {
                    Name = "Dropdown",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, ELEMENT_HEIGHT),
                    ClipsDescendants = true,
                    Parent = section.Container
                })
                
                dropdown.Label = Utility:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 0, 0, 0),
                    Size = UDim2.new(1, 0, 0, 20),
                    Font = FONT,
                    Text = options.Text,
                    TextColor3 = NexonUI.Theme.Text,
                    TextSize = TEXT_SIZE,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = dropdown.Frame
                })
                
                dropdown.Background = Utility:Create("Frame", {
                    Name = "Background",
                    BackgroundColor3 = NexonUI.Theme.Card,
                    Position = UDim2.new(0, 0, 0, 24),
                    Size = UDim2.new(1, 0, 0, 30),
                    Parent = dropdown.Frame
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(0, CORNER_RADIUS - 2),
                    Parent = dropdown.Background
                })
                
                dropdown.Selected = Utility:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -20, 1, 0),
                    Font = FONT,
                    Text = (options.MultiSelect and #dropdown.Value > 0) and table.concat(dropdown.Value, ", ") or dropdown.Value,
                    TextColor3 = NexonUI.Theme.Text,
                    TextSize = TEXT_SIZE,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Parent = dropdown.Background
                })
                
                dropdown.Arrow = Utility:Create("ImageLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -25, 0.5, 0),
                    Size = UDim2.new(0, 15, 0, 15),
                    Rotation = 0,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Image = "rbxassetid://10723407385", -- Down arrow
                    ImageColor3 = NexonUI.Theme.Text,
                    Parent = dropdown.Background
                })
                
                dropdown.Button = Utility:Create("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "",
                    Parent = dropdown.Background
                })
                
                dropdown.ItemsHolder = Utility:Create("Frame", {
                    Name = "ItemsHolder",
                    BackgroundColor3 = NexonUI.Theme.Card,
                    Position = UDim2.new(0, 0, 0, 60),
                    Size = UDim2.new(1, 0, 0, 0),
                    ClipsDescendants = true,
                    Visible = false,
                    Parent = dropdown.Frame
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(0, CORNER_RADIUS - 2),
                    Parent = dropdown.ItemsHolder
                })
                
                dropdown.ItemsFrame = Utility:Create("ScrollingFrame", {
                    Name = "ItemsFrame",
                    Active = true,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 0, 0),
                    Size = UDim2.new(1, 0, 1, 0),
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    ScrollBarThickness = 2,
                    ScrollBarImageColor3 = NexonUI.Theme.Accent,
                    Parent = dropdown.ItemsHolder
                })
                
                Utility:Create("UIPadding", {
                    PaddingTop = UDim.new(0, 5),
                    PaddingBottom = UDim.new(0, 5),
                    PaddingLeft = UDim.new(0, 5),
                    PaddingRight = UDim.new(0, 5),
                    Parent = dropdown.ItemsFrame
                })
                
                local itemsLayout = Utility:Create("UIListLayout", {
                    Padding = UDim.new(0, 5),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = dropdown.ItemsFrame
                })
                
                -- Update canvas size when items are added
                itemsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    dropdown.ItemsFrame.CanvasSize = UDim2.new(0, 0, 0, itemsLayout.AbsoluteContentSize.Y)
                end)
                
                -- Smooth scrolling
                Utility:SmoothScroll(dropdown.ItemsFrame)
                
                -- Populate items
                local function createItem(name)
                    local item = Utility:Create("Frame", {
                        Name = name .. "Item",
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 25),
                        Parent = dropdown.ItemsFrame
                    })
                    
                    local button = Utility:Create("TextButton", {
                        BackgroundColor3 = NexonUI.Theme.Section,
                        Size = UDim2.new(1, 0, 1, 0),
                        Font = FONT,
                        Text = name,
                        TextColor3 = NexonUI.Theme.Text,
                        TextSize = TEXT_SIZE,
                        Parent = item
                    })
                    
                    Utility:Create("UICorner", {
                        CornerRadius = UDim.new(0, CORNER_RADIUS - 3),
                        Parent = button
                    })
                    
                    -- Add ripple effect
                    Utility:Ripple(button)
                    
                    -- Handle multiselect
                    if options.MultiSelect then
                        local selectedIndicator = Utility:Create("Frame", {
                            BackgroundColor3 = NexonUI.Theme.Accent,
                            Position = UDim2.new(1, -25, 0.5, 0),
                            Size = UDim2.new(0, 16, 0, 16),
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Parent = button
                        })
                        
                        Utility:Create("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                            Parent = selectedIndicator
                        })
                        
                        local check = Utility:Create("ImageLabel", {
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 1, 0),
                            Image = "rbxassetid://10723441859", -- Checkmark
                            ImageColor3 = NexonUI.Theme.Text,
                            ImageTransparency = 1, -- Hidden initially
                            Parent = selectedIndicator
                        })
                        
                        -- Update initial state if in selected list
                        if table.find(dropdown.Value, name) then
                            check.ImageTransparency = 0
                        end
                        
                        button.MouseButton1Click:Connect(function()
                            local found = table.find(dropdown.Value, name)
                            if found then
                                table.remove(dropdown.Value, found)
                                Utility:Tween(check, {ImageTransparency = 1}, 0.2)
                            else
                                table.insert(dropdown.Value, name)
                                Utility:Tween(check, {ImageTransparency = 0}, 0.2)
                            end
                            
                            dropdown.Selected.Text = #dropdown.Value > 0 and table.concat(dropdown.Value, ", ") or "None"
                            
                            if options.Flag then
                                NexonUI.Flags[options.Flag] = dropdown.Value
                            end
                            
                            options.Callback(dropdown.Value)
                        end)
                    else
                        button.MouseButton1Click:Connect(function()
                            dropdown:Toggle() -- Close dropdown
                            
                            dropdown.Value = name
                            dropdown.Selected.Text = name
                            
                            if options.Flag then
                                NexonUI.Flags[options.Flag] = name
                            end
                            
                            options.Callback(name)
                        end)
                    end
                    
                    return item
                end
                
                -- Toggle dropdown state
                function dropdown:Toggle()
                    dropdown.Open = not dropdown.Open
                    
                    local targetSize = dropdown.Open and 
                        math.min(120, #options.Items * 30 + 10) or 0
                    
                    if dropdown.Open then
                        dropdown.ItemsHolder.Visible = true
                        
                        Utility:Tween(dropdown.ItemsHolder, {
                            Size = UDim2.new(1, 0, 0, targetSize)
                        }, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                        
                        Utility:Tween(dropdown.Frame, {
                            Size = UDim2.new(1, 0, 0, ELEMENT_HEIGHT + targetSize + 6)
                        }, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                        
                        Utility:Tween(dropdown.Arrow, {Rotation = 180}, 0.3)
                    else
                        Utility:Tween(dropdown.ItemsHolder, {
                            Size = UDim2.new(1, 0, 0, 0)
                        }, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, function()
                            dropdown.ItemsHolder.Visible = false
                        end)
                        
                        Utility:Tween(dropdown.Frame, {
                            Size = UDim2.new(1, 0, 0, ELEMENT_HEIGHT)
                        }, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                        
                        Utility:Tween(dropdown.Arrow, {Rotation = 0}, 0.3)
                    end
                end
                
                -- Add items from options
                for _, item in ipairs(options.Items) do
                    createItem(item)
                end
                
                -- Toggle dropdown when button is clicked
                dropdown.Button.MouseButton1Click:Connect(function()
                    dropdown:Toggle()
                end)
                
                -- Initialize flags if needed
                if options.Flag then
                    NexonUI.Flags[options.Flag] = dropdown.Value
                end
                
                -- API
                function dropdown:SetValue(value)
                    if options.MultiSelect and type(value) == "table" then
                        dropdown.Value = value
                        dropdown.Selected.Text = #value > 0 and table.concat(value, ", ") or "None"
                        
                        -- Update visual indicators
                        for _, item in ipairs(dropdown.ItemsFrame:GetChildren()) do
                            if item:IsA("Frame") and item.Name:match("Item$") then
                                local itemName = item.Name:gsub("Item$", "")
                                local indicator = item:FindFirstChild("TextButton"):FindFirstChild("Frame")
                                
                                if indicator and indicator:FindFirstChild("ImageLabel") then
                                    local check = indicator.ImageLabel
                                    if table.find(value, itemName) then
                                        check.ImageTransparency = 0
                                    else
                                        check.ImageTransparency = 1
                                    end
                                end
                            end
                        end
                    elseif not options.MultiSelect then
                        dropdown.Value = value
                        dropdown.Selected.Text = value
                    end
                    
                    if options.Flag then
                        NexonUI.Flags[options.Flag] = dropdown.Value
                    end
                    
                    options.Callback(dropdown.Value)
                end
                
                function dropdown:AddItem(item)
                    if table.find(options.Items, item) then return end
                    
                    table.insert(options.Items, item)
                    createItem(item)
                end
                
                function dropdown:RemoveItem(item)
                    local index = table.find(options.Items, item)
                    if not index then return end
                    
                    table.remove(options.Items, index)
                    
                    -- Remove from UI
                    for _, child in ipairs(dropdown.ItemsFrame:GetChildren()) do
                        if child.Name == item.."Item" then
                            child:Destroy()
                            break
                        end
                    end
                    
                    -- Remove from value if selected
                    if options.MultiSelect then
                        local valueIndex = table.find(dropdown.Value, item)
                        if valueIndex then
                            table.remove(dropdown.Value, valueIndex)
                            dropdown.Selected.Text = #dropdown.Value > 0 and table.concat(dropdown.Value, ", ") or "None"
                        end
                    elseif dropdown.Value == item then
                        dropdown.Value = ""
                        dropdown.Selected.Text = "None"
                    end
                    
                    if options.Flag then
                        NexonUI.Flags[options.Flag] = dropdown.Value
                    end
                    
                    options.Callback(dropdown.Value)
                end
                
                function dropdown:Clear()
                    dropdown.Value = options.MultiSelect and {} or ""
                    dropdown.Selected.Text = "None"
                    
                    -- Clear UI
                    for _, child in ipairs(dropdown.ItemsFrame:GetChildren()) do
                        if child:IsA("Frame") then
                            child:Destroy()
                        end
                    end
                    
                    options.Items = {}
                    
                    if options.Flag then
                        NexonUI.Flags[options.Flag] = dropdown.Value
                    end
                    
                    options.Callback(dropdown.Value)
                end
                
                function dropdown:Refresh(items)
                    dropdown:Clear()
                    
                    -- Add new items
                    options.Items = items
                    for _, item in ipairs(items) do
                        createItem(item)
                    end
                end
                
                return dropdown
            end
            
            -- Add textbox element
            function section:AddTextbox(options)
                options = options or {}
                options.Text = options.Text or "Textbox"
                options.Default = options.Default or ""
                options.Placeholder = options.Placeholder or "Enter text..."
                options.Flag = options.Flag or nil
                options.Callback = options.Callback or function() end
                
                local textbox = {}
                textbox.Value = options.Default
                
                textbox.Frame = Utility:Create("Frame", {
                    Name = "Textbox",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, ELEMENT_HEIGHT),
                    Parent = section.Container
                })
                
                textbox.Label = Utility:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 0, 0, 0),
                    Size = UDim2.new(1, 0, 0, 20),
                    Font = FONT,
                    Text = options.Text,
                    TextColor3 = NexonUI.Theme.Text,
                    TextSize = TEXT_SIZE,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = textbox.Frame
                })
                
                textbox.Background = Utility:Create("Frame", {
                    Name = "Background",
                    BackgroundColor3 = NexonUI.Theme.Card,
                    Position = UDim2.new(0, 0, 0, 24),
                    Size = UDim2.new(1, 0, 0, 30),
                    Parent = textbox.Frame
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(0, CORNER_RADIUS - 2),
                    Parent = textbox.Background
                })
                
                textbox.Input = Utility:Create("TextBox", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -20, 1, 0),
                    Font = FONT,
                    Text = options.Default,
                    TextColor3 = NexonUI.Theme.Text,
                    TextSize = TEXT_SIZE,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    PlaceholderText = options.Placeholder,
                    PlaceholderColor3 = NexonUI.Theme.SubText,
                    ClearTextOnFocus = false,
                    Parent = textbox.Background
                })
                
                -- Handle textbox focus
                textbox.Input.Focused:Connect(function()
                    Utility:Tween(textbox.Background, {
                        BackgroundColor3 = NexonUI.Theme.Accent
                    }, 0.2)
                end)
                
                textbox.Input.FocusLost:Connect(function(enterPressed)
                    Utility:Tween(textbox.Background, {
                        BackgroundColor3 = NexonUI.Theme.Card
                    }, 0.2)
                    
                    if textbox.Value ~= textbox.Input.Text then
                        textbox.Value = textbox.Input.Text
                        
                        if options.Flag then
                            NexonUI.Flags[options.Flag] = textbox.Value
                        end
                        
                        options.Callback(textbox.Value, enterPressed)
                    end
                end)
                
                -- Initialize flags if needed
                if options.Flag then
                    NexonUI.Flags[options.Flag] = textbox.Value
                end
                
                -- API
                function textbox:SetValue(value)
                    textbox.Value = value
                    textbox.Input.Text = value
                    
                    if options.Flag then
                        NexonUI.Flags[options.Flag] = value
                    end
                    
                    options.Callback(value, false)
                end
                
                return textbox
            end
            
            -- Add keybind element
            function section:AddKeybind(options)
                options = options or {}
                options.Text = options.Text or "Keybind"
                options.Default = options.Default or Enum.KeyCode.Unknown
                options.Flag = options.Flag or nil
                options.Callback = options.Callback or function() end
                
                local keybind = {}
                keybind.Value = options.Default
                keybind.Listening = false
                
                keybind.Frame = Utility:Create("Frame", {
                    Name = "Keybind",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, ELEMENT_HEIGHT),
                    Parent = section.Container
                })
                
                keybind.Label = Utility:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 0, 0, 0),
                    Size = UDim2.new(1, -80, 1, 0),
                    Font = FONT,
                    Text = options.Text,
                    TextColor3 = NexonUI.Theme.Text,
                    TextSize = TEXT_SIZE,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = keybind.Frame
                })
                
                keybind.Background = Utility:Create("Frame", {
                    Name = "Background",
                    BackgroundColor3 = NexonUI.Theme.Card,
                    Position = UDim2.new(1, -70, 0.5, 0),
                    Size = UDim2.new(0, 70, 0, 25),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Parent = keybind.Frame
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(0, CORNER_RADIUS - 2),
                    Parent = keybind.Background
                })
                
                keybind.Button = Utility:Create("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Font = FONT,
                    Text = keybind.Value ~= Enum.KeyCode.Unknown and keybind.Value.Name or "None",
                    TextColor3 = NexonUI.Theme.Text,
                    TextSize = TEXT_SIZE,
                    Parent = keybind.Background
                })
                
                -- Ripple effect
                Utility:Ripple(keybind.Button)
                
                -- Handle keybind button click
                keybind.Button.MouseButton1Click:Connect(function()
                    if keybind.Listening then return end
                    
                    keybind.Listening = true
                    keybind.Button.Text = "..."
                    
                    Utility:Tween(keybind.Background, {
                        BackgroundColor3 = NexonUI.Theme.Accent
                    }, 0.2)
                end)
                
                -- Listen for key press
                UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if keybind.Listening and input.UserInputType == Enum.UserInputType.Keyboard then
                        keybind.Value = input.KeyCode
                        keybind.Button.Text = input.KeyCode.Name
                        keybind.Listening = false
                        
                        Utility:Tween(keybind.Background, {
                            BackgroundColor3 = NexonUI.Theme.Card
                        }, 0.2)
                        
                        if options.Flag then
                            NexonUI.Flags[options.Flag] = keybind.Value
                        end
                        
                        options.Callback(keybind.Value)
                    elseif not gameProcessed and input.KeyCode == keybind.Value then
                        options.Callback(keybind.Value)
                    end
                end)
                
                -- Initialize flags if needed
                if options.Flag then
                    NexonUI.Flags[options.Flag] = keybind.Value
                end
                
                -- API
                function keybind:SetValue(value)
                    keybind.Value = value
                    keybind.Button.Text = value ~= Enum.KeyCode.Unknown and value.Name or "None"
                    
                    if options.Flag then
                        NexonUI.Flags[options.Flag] = value
                    end
                    
                    options.Callback(value)
                end
                
                return keybind
            end
            
            -- Add ColorPicker element
            function section:AddColorPicker(options)
                options = options or {}
                options.Text = options.Text or "Color Picker"
                options.Default = options.Default or Color3.fromRGB(255, 255, 255)
                options.Flag = options.Flag or nil
                options.Callback = options.Callback or function() end
                
                local colorPicker = {}
                colorPicker.Value = options.Default
                colorPicker.Open = false
                
                colorPicker.Frame = Utility:Create("Frame", {
                    Name = "ColorPicker",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, ELEMENT_HEIGHT),
                    Parent = section.Container
                })
                
                colorPicker.Label = Utility:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 0, 0, 0),
                    Size = UDim2.new(1, -40, 1, 0),
                    Font = FONT,
                    Text = options.Text,
                    TextColor3 = NexonUI.Theme.Text,
                    TextSize = TEXT_SIZE,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = colorPicker.Frame
                })
                
                colorPicker.Display = Utility:Create("Frame", {
                    Name = "Display",
                    BackgroundColor3 = colorPicker.Value,
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, -30, 0.5, 0),
                    Size = UDim2.new(0, 30, 0, 30),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Parent = colorPicker.Frame
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(0, CORNER_RADIUS - 2),
                    Parent = colorPicker.Display
                })
                
                colorPicker.Button = Utility:Create("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "",
                    Parent = colorPicker.Display
                })
                
                -- Create color picker panel (appears when clicked)
                colorPicker.Panel = Utility:Create("Frame", {
                    Name = "Panel",
                    BackgroundColor3 = NexonUI.Theme.Card,
                    Position = UDim2.new(1, 5, 0, 0),
                    Size = UDim2.new(0, 200, 0, 200),
                    Visible = false,
                    ZIndex = 10,
                    Parent = colorPicker.Frame
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(0, CORNER_RADIUS),
                    Parent = colorPicker.Panel
                })
                
                -- Add shadow
                Utility:CreateShadow(colorPicker.Panel, 1)
                
                -- Add basic color picker elements
                -- This is a simplified version - In a complete implementation,
                -- we would add HSV picker, RGB sliders, etc.
                
                -- Add some preset colors
                local presets = {
                    Color3.fromRGB(255, 255, 255), -- White
                    Color3.fromRGB(0, 0, 0),       -- Black
                    Color3.fromRGB(255, 0, 0),     -- Red
                    Color3.fromRGB(0, 255, 0),     -- Green
                    Color3.fromRGB(0, 0, 255),     -- Blue
                    Color3.fromRGB(255, 255, 0),   -- Yellow
                    Color3.fromRGB(255, 0, 255),   -- Magenta
                    Color3.fromRGB(0, 255, 255),   -- Cyan
                    NexonUI.Theme.Accent,          -- Theme accent
                }
                
                -- Add title
                Utility:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 5),
                    Size = UDim2.new(1, -20, 0, 20),
                    Font = FONT,
                    Text = "Choose Color",
                    TextColor3 = NexonUI.Theme.Text,
                    TextSize = TEXT_SIZE,
                    ZIndex = 10,
                    Parent = colorPicker.Panel
                })
                
                -- Add preset colors
                local presetsContainer = Utility:Create("Frame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 30),
                    Size = UDim2.new(1, -20, 0, 60),
                    ZIndex = 10,
                    Parent = colorPicker.Panel
                })
                
                local presetsLayout = Utility:Create("UIGridLayout", {
                    CellPadding = UDim2.new(0, 5, 0, 5),
                    CellSize = UDim2.new(0, 30, 0, 30),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = presetsContainer
                })
                
                -- Create preset buttons
                for i, color in ipairs(presets) do
                    local presetButton = Utility:Create("TextButton", {
                        BackgroundColor3 = color,
                        BorderSizePixel = 0,
                        Text = "",
                        ZIndex = 10,
                        Parent = presetsContainer
                    })
                    
                    Utility:Create("UICorner", {
                        CornerRadius = UDim.new(0, CORNER_RADIUS - 3),
                        Parent = presetButton
                    })
                    
                    -- Button click
                    presetButton.MouseButton1Click:Connect(function()
                        colorPicker.Value = color
                        colorPicker.Display.BackgroundColor3 = color
                        
                        if options.Flag then
                            NexonUI.Flags[options.Flag] = color
                        end
                        
                        options.Callback(color)
                    end)
                end
                
                -- Add RGB inputs
                local rgbContainer = Utility:Create("Frame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 100),
                    Size = UDim2.new(1, -20, 0, 90),
                    ZIndex = 10,
                    Parent = colorPicker.Panel
                })
                
                local labels = {"R:", "G:", "B:"}
                local rgbValues = {
                    math.floor(colorPicker.Value.R * 255),
                    math.floor(colorPicker.Value.G * 255),
                    math.floor(colorPicker.Value.B * 255)
                }
                
                local rgbInputs = {}
                
                for i, label in ipairs(labels) do
                    local labelText = Utility:Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 0, 0, (i-1) * 30),
                        Size = UDim2.new(0, 20, 0, 25),
                        Font = FONT,
                        Text = label,
                        TextColor3 = NexonUI.Theme.Text,
                        TextSize = TEXT_SIZE,
                        ZIndex = 10,
                        Parent = rgbContainer
                    })
                    
                    local inputBackground = Utility:Create("Frame", {
                        BackgroundColor3 = NexonUI.Theme.Background,
                        Position = UDim2.new(0, 30, 0, (i-1) * 30),
                        Size = UDim2.new(1, -40, 0, 25),
                        ZIndex = 10,
                        Parent = rgbContainer
                    })
                    
                    Utility:Create("UICorner", {
                        CornerRadius = UDim.new(0, CORNER_RADIUS - 3),
                        Parent = inputBackground
                    })
                    
                    local input = Utility:Create("TextBox", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 10, 0, 0),
                        Size = UDim2.new(1, -20, 1, 0),
                        Font = FONT,
                        Text = tostring(rgbValues[i]),
                        TextColor3 = NexonUI.Theme.Text,
                        TextSize = TEXT_SIZE,
                        ZIndex = 10,
                        Parent = inputBackground
                    })
                    
                    rgbInputs[i] = input
                    
                    -- Handle input changes
                    input.FocusLost:Connect(function(enterPressed)
                        local value = tonumber(input.Text)
                        if value then
                            value = math.clamp(value, 0, 255)
                            input.Text = tostring(value)
                            rgbValues[i] = value
                            
                            local newColor = Color3.fromRGB(
                                rgbValues[1],
                                rgbValues[2],
                                rgbValues[3]
                            )
                            
                            colorPicker.Value = newColor
                            colorPicker.Display.BackgroundColor3 = newColor
                            
                            if options.Flag then
                                NexonUI.Flags[options.Flag] = newColor
                            end
                            
                            options.Callback(newColor)
                        else
                            input.Text = tostring(rgbValues[i])
                        end
                    end)
                end
                
                -- Toggle color picker panel
                local function togglePanel()
                    colorPicker.Open = not colorPicker.Open
                    colorPicker.Panel.Visible = colorPicker.Open
                end
                
                -- Button click to open picker
                colorPicker.Button.MouseButton1Click:Connect(togglePanel)
                
                -- Close panel when clicking elsewhere
                UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        if colorPicker.Open then
                            local position = input.Position
                            local panelPosition = colorPicker.Panel.AbsolutePosition
                            local panelSize = colorPicker.Panel.AbsoluteSize
                            
                            if position.X < panelPosition.X or
                               position.Y < panelPosition.Y or
                               position.X > panelPosition.X + panelSize.X or
                               position.Y > panelPosition.Y + panelSize.Y then
                                
                                if position.X < colorPicker.Display.AbsolutePosition.X or
                                   position.Y < colorPicker.Display.AbsolutePosition.Y or
                                   position.X > colorPicker.Display.AbsolutePosition.X + colorPicker.Display.AbsoluteSize.X or
                                   position.Y > colorPicker.Display.AbsolutePosition.Y + colorPicker.Display.AbsoluteSize.Y then
                                    
                                    togglePanel()
                                end
                            end
                        end
                    end
                end)
                
                -- Initialize flags if needed
                if options.Flag then
                    NexonUI.Flags[options.Flag] = colorPicker.Value
                end
                
                -- API
                function colorPicker:SetValue(color)
                    colorPicker.Value = color
                    colorPicker.Display.BackgroundColor3 = color
                    
                    -- Update RGB inputs
                    rgbInputs[1].Text = tostring(math.floor(color.R * 255))
                    rgbInputs[2].Text = tostring(math.floor(color.G * 255))
                    rgbInputs[3].Text = tostring(math.floor(color.B * 255))
                    
                    rgbValues = {
                        math.floor(color.R * 255),
                        math.floor(color.G * 255),
                        math.floor(color.B * 255)
                    }
                    
                    if options.Flag then
                        NexonUI.Flags[options.Flag] = color
                    end
                    
                    options.Callback(color)
                end
                
                return colorPicker
            end
            
            return section
        end
        
        return tab
    end
    
    -- Select a tab by name
    function window:SelectTab(tabName)
        if self.Tabs[tabName] then
            if self.ActiveTab == tabName then
                return
            end
            
            -- Deselect all tabs
            for name, tab in pairs(self.Tabs) do
                if name ~= tabName then
                    Utility:Tween(tab.Button, {
                        BackgroundColor3 = NexonUI.Theme.Card,
                        BackgroundTransparency = 0.7,
                        TextColor3 = NexonUI.Theme.SubText
                    }, 0.3)
                    
                    if tab.Icon then
                        Utility:Tween(tab.Icon, {
                            ImageColor3 = NexonUI.Theme.SubText
                        }, 0.3)
                    end
                    
                    tab.Container.Visible = false
                end
            end
            
            -- Select target tab
            local targetTab = self.Tabs[tabName]
            Utility:Tween(targetTab.Button, {
                BackgroundColor3 = NexonUI.Theme.Accent,
                BackgroundTransparency = 0.3,
                TextColor3 = NexonUI.Theme.Text
            }, 0.3)
            
            if targetTab.Icon then
                Utility:Tween(targetTab.Icon, {
                    ImageColor3 = NexonUI.Theme.Text
                }, 0.3)
            end
            
            targetTab.Container.Visible = true
            self.ActiveTab = tabName
        end
    end
    
    table.insert(self.Windows, window)
    return window
end
-- ฟังก์ชัน CreateToggleButton สำหรับสร้างปุ่มเปิด/ปิด UI สวยๆ
function NexonUI:CreateToggleButton()
    -- สร้างปุ่มลอยบนพื้นที่ว่าง
    local toggleButton = Utility:Create("ImageButton", {
        Name = "ToggleButton",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0.5, -25),
        Size = UDim2.new(0, 50, 0, 50),
        Image = "rbxassetid://7733658504", -- ไอคอน Menu (เปลี่ยน ID ตามต้องการ)
        ImageColor3 = self.Theme.Accent,
        ZIndex = 1000,
        Parent = self.ScreenGui
    })
    
    -- เพิ่มเอฟเฟคเงาให้กับปุ่ม
    local shadow = Utility:Create("ImageLabel", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1.5, 0, 1.5, 0),
        Image = "rbxassetid://7743878857", -- รูปเงากลม
        ImageColor3 = SHADOW_COLOR,
        ImageTransparency = 0.4,
        ZIndex = 999,
        Parent = toggleButton
    })
    
    -- เพิ่มวงกลมเรืองแสงรอบปุ่ม
    local glow = Utility:Create("ImageLabel", {
        Name = "Glow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1.7, 0, 1.7, 0),
        Image = "rbxassetid://7743878857", -- รูปวงกลม
        ImageColor3 = self.Theme.Accent,
        ImageTransparency = 0.7,
        ZIndex = 998,
        Parent = toggleButton
    })
    
    -- สถานะเปิด/ปิด UI
    local isOpen = true
    
    -- ฟังก์ชั่นเปิด/ปิด UI
    local function toggleUI()
        isOpen = not isOpen
        
        -- หมุนปุ่มเป็นเอฟเฟค
        Utility:Tween(toggleButton, {Rotation = toggleButton.Rotation + 180}, 0.4, Enum.EasingStyle.Back)
        
        -- เปลี่ยนสีปุ่มตามสถานะ
        local targetColor = isOpen and self.Theme.Accent or self.Theme.Error
        Utility:Tween(toggleButton, {ImageColor3 = targetColor}, 0.3)
        Utility:Tween(glow, {ImageColor3 = targetColor}, 0.3)
        
        -- สร้างเอฟเฟคเรืองแสงเมื่อกด
        Utility:Tween(glow, {ImageTransparency = 0.5, Size = UDim2.new(2, 0, 2, 0)}, 0.2)
        task.delay(0.2, function()
            Utility:Tween(glow, {ImageTransparency = 0.7, Size = UDim2.new(1.7, 0, 1.7, 0)}, 0.2)
        end)
        
        -- เลื่อน UI ออกจากหน้าจอหรือกลับเข้ามา
        for _, window in ipairs(self.Windows) do
            if isOpen then
                -- เลื่อน UI กลับเข้ามา
                Utility:Tween(window.Frame, {
                    Position = window.OriginalPosition or UDim2.new(0.5, -window.Frame.AbsoluteSize.X/2, 0.5, -window.Frame.AbsoluteSize.Y/2)
                }, 0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            else
                -- บันทึกตำแหน่งปัจจุบัน
                window.OriginalPosition = window.Frame.Position
                
                -- เลื่อน UI ออกไปนอกหน้าจอ
                Utility:Tween(window.Frame, {
                    Position = UDim2.new(-1, 0, window.Frame.Position.Y.Scale, window.Frame.Position.Y.Offset)
                }, 0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            end
        end
    end
    
    -- เอฟเฟคเมื่อนำเมาส์ไปวาง
    toggleButton.MouseEnter:Connect(function()
        Utility:Tween(toggleButton, {Size = UDim2.new(0, 60, 0, 60)}, 0.3, Enum.EasingStyle.Back)
        Utility:Tween(glow, {ImageTransparency = 0.5}, 0.3)
    end)
    
    toggleButton.MouseLeave:Connect(function()
        Utility:Tween(toggleButton, {Size = UDim2.new(0, 50, 0, 50)}, 0.3, Enum.EasingStyle.Back)
        Utility:Tween(glow, {ImageTransparency = 0.7}, 0.3)
    end)
    
    -- เรียกใช้ฟังก์ชั่นเมื่อคลิกปุ่ม
    toggleButton.MouseButton1Click:Connect(toggleUI)
    
    -- สร้าง API สำหรับเรียกใช้จากภายนอก
    local api = {
        Toggle = toggleUI,
        SetState = function(state)
            if state ~= isOpen then
                toggleUI()
            end
        end,
        GetState = function()
            return isOpen
        end,
        Button = toggleButton
    }
    
    -- ลงทะเบียนปุ่มกับ UI
    self.ToggleButton = api
    
    return api
end

-- โค้ดตัวอย่างการใช้งาน:
-- local toggleButton = NexonUI:CreateToggleButton()
-- 
-- -- เปิดใช้งานฟังก์ชันผ่าน API
-- toggleButton:Toggle() -- สลับสถานะเปิด/ปิด
-- toggleButton:SetState(true) -- กำหนดให้เปิด UI
-- toggleButton:SetState(false) -- กำหนดให้ปิด UI
-- local isOpen = toggleButton:GetState() -- เช็คสถานะ
-- Notification system
function NexonUI:Notify(options)
    self:Init()
    
    options = options or {}
    options.Title = options.Title or "Notification"
    options.Content = options.Content or "This is a notification."
    options.Duration = options.Duration or 5
    options.Type = options.Type or "Info" -- Info, Success, Warning, Error
    
    -- Determine color based on type
    local accentColor
    if options.Type == "Success" then
        accentColor = self.Theme.Success
    elseif options.Type == "Warning" then
        accentColor = self.Theme.Warning
    elseif options.Type == "Error" then
        accentColor = self.Theme.Error
    else
        accentColor = self.Theme.Accent
    end
    
    -- Create notification frame
    local notification = {}
    
    notification.Frame = Utility:Create("Frame", {
        Name = "Notification",
        AnchorPoint = Vector2.new(1, 0),
        BackgroundColor3 = self.Theme.Card,
        Position = UDim2.new(1, 20, 0, 0), -- Start outside screen
        Size = UDim2.new(0, 300, 0, 80),
        Parent = self.NotificationHolder
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, CORNER_RADIUS),
        Parent = notification.Frame
    })
    
    -- Add shadow
    Utility:CreateShadow(notification.Frame, 1)
    
    -- Add color accent bar
    notification.Accent = Utility:Create("Frame", {
        Name = "Accent",
        BackgroundColor3 = accentColor,
        Size = UDim2.new(0, 4, 1, 0),
        Parent = notification.Frame
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, CORNER_RADIUS),
        Parent = notification.Accent
    })
    
    -- Add title
    notification.Title = Utility:Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 10),
        Size = UDim2.new(1, -25, 0, 20),
        Font = FONT,
        Text = options.Title,
        TextColor3 = self.Theme.Text,
        TextSize = TEXT_SIZE + 2,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notification.Frame
    })
    
    -- Add content
    notification.Content = Utility:Create("TextLabel", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 35),
        Size = UDim2.new(1, -25, 0, 35),
        Font = FONT,
        Text = options.Content,
        TextColor3 = self.Theme.SubText,
        TextSize = TEXT_SIZE,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notification.Frame
    })
    
    -- Add close button
    notification.CloseButton = Utility:Create("ImageButton", {
        Name = "CloseButton",
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -25, 0, 10),
        Size = UDim2.new(0, 15, 0, 15),
        Image = "rbxassetid://10734898835",
        ImageColor3 = self.Theme.SubText,
        Parent = notification.Frame
    })
    
    -- Add progress bar
    notification.ProgressBar = Utility:Create("Frame", {
        Name = "ProgressBar",
        BackgroundColor3 = accentColor,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -2),
        Size = UDim2.new(1, 0, 0, 2),
        Parent = notification.Frame
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 2),
        Parent = notification.ProgressBar
    })
    
    -- Animation to show notification
    Utility:Tween(notification.Frame, {
        Position = UDim2.new(1, -10, 0, 0)
    }, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    
    -- Progress bar animation
    Utility:Tween(notification.ProgressBar, {
        Size = UDim2.new(0, 0, 0, 2)
    }, options.Duration, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
    
    -- Close notification when close button is clicked
    notification.CloseButton.MouseButton1Click:Connect(function()
        Utility:Tween(notification.Frame, {
            Position = UDim2.new(1, 20, 0, notification.Frame.Position.Y.Offset)
        }, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, function()
            notification.Frame:Destroy()
        end)
    end)
    
    -- Auto-close notification after duration
    task.delay(options.Duration, function()
        if notification.Frame.Parent then
            Utility:Tween(notification.Frame, {
                Position = UDim2.new(1, 20, 0, notification.Frame.Position.Y.Offset)
            }, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, function()
                notification.Frame:Destroy()
            end)
        end
    end)
    
    -- Return the notification object
    return notification
end

-- Get a flag value
function NexonUI:GetFlag(flag)
    return self.Flags[flag]
end

-- Set a flag value
function NexonUI:SetFlag(flag, value)
    self.Flags[flag] = value
    return self.Flags[flag]
end

-- Return the library
return NexonUI
