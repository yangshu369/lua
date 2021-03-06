local M = {}


function M.init()
    local structure = require("kernel.structure")
    M.msgList = structure.newList()     --消息列表
    M.seq = 1                           --Ai的递增ID
    M.objPool = {}                      --ai角色列表
    M.statePool =  {}                   --状态列表
end

function M.addObject(obj)           --为obj加入状态机
    obj.fsmID = tostring(M.seq)
    M.seq = M.seq + 1
    M.objPool[obj.fsmID] = obj
    obj.fsmStateList = {}           --多状态列表
    obj.fsmStateDataList ={}        --多状态数据
    
    function obj:deleteFsm()             --释放状态
       M.objPool[self.fsmID] = nil
       self.fsmStateList = nil
       self.fsmStateDataLis = nil
       self.fsmID =nil
    end
    
    --改变状态 状态类属, 状态名, 
    function obj:changeFsmState(key, stateName)         --改变状态
        if self.fsmStateList[key] ~= nil then
            self.fsmStateList[key]:quit(self)
        end
        self.fsmStateList[key] = M.statePool[stateName]
        self.fsmStateList[key]:start(self)
    end
    
    --改变状态数据 状态类属, 数据
    function obj:changeFsmStateData(key, data)
         self.fsmStateDataList[key] = data
    end
    
    --获取当前状态name 状态类属
    function obj:getFsmStatuName(key)
         return self.fsmStateList[key]:getName()
    end
    
    --获取当前状态数据
    function obj:getFsmStatuData(key)
         return self.fsmStateDataList[key]
    end
    
    --处理消息 消息id, 数据
    function obj:dispatchFsmMsg(MsgID, data)
        for key, state in pairs(self.fsmStateList) do
            state:dispatchFsmMsg(self, MsgID, data)
        end
    end
end

function M.update(deltaTime)         --更新状态机 时间增量
    for id, obj in pairs(M.objPool) do
        for key, state in pairs(obj.fsmStateList) do
            state:update(deltaTime, obj)
        end
    end
    local currentTime = system.getTimer()
    local deleteData = {}
    for element in M.msgList:foreach() do
        if element.deltaTime >= currentTime then
            local obj = M.objPool[element.recvFsmID]
            if obj then
                obj:dispatchFsmMsg(element.msgID, element.data)
            end
            deleteData[#deleteData+1] = element
        end
    end

    for i = 1, #deleteData do
        M.msgList:remove(deleteData[i])
    end
end

--加入状态到fsm 状态名，状态
function M.addState(stateName, state)
    M.statePool[stateName] = state
end

--发送消息 接受者id 消息id 数据 延迟时间
function M.sendMsg(recvFsmID, msgID, data, deltaTime)
    if deltaTime then
        local currentTime = system.getTimer()
        M.msgList:insert({deltaTime = currentTime + deltaTime,
                                   recvFsmID = recvFsmID,
                                   msgID = msgID,
                                   data = data})
    else
        local obj = M.objPool[recvFsmID]
        if obj then
            obj:dispatchFsmMsg(msgID, data)
        end
    end
end

function M.newBaseState()                   --基础状态类
    local state = {}
    
    function state:start(obj)
        error("未继承")
    end
    
    function state:quit(obj)
        error("未继承")
    end
    
    function state:update(deltaTime, obj)
        error("未继承")
    end
    
    function state:getName()
        error("未继承")
    end
    
    --处理消息 ai对象 消息id, 数据
    function state:dispatchFsmMsg(obj, MsgID, data)

    end
    
    return state
end

M.init()

return M


--测试
--local fsm = require("kernel.fsm")
--fsm.init()
--easeModule.init()
--local baseState = fsm.newBaseState()
--local moveState = {}
--moveState.super = baseState
--setmetatable(moveState, {__index=baseState})
--function moveState:start(obj)
--        obj:changeFsmStateData("statu", {isMove = false})
--    end
--    
--function moveState:quit(obj)
--    obj:changeFsmStateData("statu", nil)
--end
--
--math.randomseed(os.time())
--function moveState:update(deltaTime, obj)
--    local moveData = obj:getFsmStatuData("statu")
--    if moveData.isMove == false then
--        easeModule.addObject(obj, { x = math.random(width), 
--        y = math.random(height)}, math.random(3000), function(target)
--             target:changeFsmStateData("statu", {isMove = false})
--        end)
--        obj:changeFsmStateData("statu", {isMove = true})
--    end
--end
--
--function moveState:getName()
--    return "moveState"
--end
--
--fsm.addState("moveState", moveState)
--fsm.addObject(obj)
--obj:changeFsmState("statu", "moveState")
--
----处理消息 ai对象 消息id, 数据
--function moveState:dispatchFsmMsg(obj, MsgID, data)
--    if MsgID == "sb" then
--        obj:deleteFsm()
--    elseif MsgID == "zhuan" then
--        obj.alpha = 0.3
--    end
--    
--end
--
--
--timer.performWithDelay(5000, function() 
--    fsm.sendMsg(obj.fsmID, "zhuan", {})
--end, 1)
--
