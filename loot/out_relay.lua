TEST_MAX_TIME = 60 * 60

function onFinished()
    print(getReturnValue(0x7E2000)) -- tilemap address
    emu.stop(0)
end

function onErrorSignaled()
    print("err")
    emu.stop(1)
end

-- Fail the test for taking too long
function timeoutFail()
    if emu.getState()["frameCount"] > TEST_MAX_TIME then
        print("Emulator took too long to run")
        emu.stop(1)
    end
end

-- Reads memory as a Lua string
function getReturnValue(start)
    local addr = start
    local retval = ""
    local char = emu.read(addr, emu.memType.cpuDebug, false)
    
    while char ~= 0x80 do
        retval = retval .. string.char(char)
        addr = addr + 2 -- stored in tilemap every other byte (tilemap format)
        char = emu.read(addr, emu.memType.cpuDebug, false)
    end
    
    return retval
end

-- set up testing environment and callbacks
noErr = emu.addMemoryCallback(onFinished, emu.callbackType.write, 0x002000)
error = emu.addMemoryCallback(onErrorSignaled, emu.callbackType.write, 0x002001)
timeout = emu.addEventCallback(timeoutFail, emu.eventType.startFrame)

