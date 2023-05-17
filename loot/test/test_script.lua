TEST_MAX_TIME = 60 * 5   -- max test time 5 seconds

ROMName = emu.getRomInfo()["name"]

-- Loads in the expected outputs and answer as string, and also
-- gets the source of the input buffer for copying later.
function loadTestExpectations()
    local addr = 0xC10000
    local char = emu.read(addr, emu.memType.cpuDebug, false)
    expectedOutput = ""

    -- For ease of transmission, the expected result of the test is compiled
    -- into the ROM (it begins at address $C10000, which is outside the range
    -- of other stuff)
    char = emu.read(addr, emu.memType.cpuDebug, false)
    while char ~= 0 do
        expectedOutput = expectedOutput .. string.char(char)
        addr = addr + 1
        char = emu.read(addr, emu.memType.cpuDebug, false)
    end
    
    emu.displayMessage("ANSWER", expectedAnswer)
    emu.displayMessage("OUTPUT", expectedOutput)
end

-- When the program is finished (in a non-error state), inspect outputs
-- to ensure that the correct result and outputs are reached.
--
-- Output = result of program
function onFinished()

    local actualOutput = getReturnValue(0x7E2000) -- tilemap address

    if expectedOutput == "'err" then
        emu.displayMessage("FAILURE", "error expected but did not happen")
        emu.displayMessage("EXPECTED", expectedAnswer);
        print("-------------------------")
        print("TEST FAILED: " .. ROMName)
        print("An error was expected but did not happen.")
        print("  Actual  : " .. actualOutput)
        print("-------------------------")
        emu.stop(1)
    elseif actualOutput ~= expectedOutput then
        emu.displayMessage("FAILURE", "expected output did not match")
        emu.displayMessage("EXPECTED", expectedOutput);
        emu.displayMessage("ACTUAL", actualOutput);
        print("-------------------------")
        print("TEST FAILED: " .. ROMName)
        print("Output values did not match.")
        print("  Expected: " .. expectedOutput)
        print("  Actual  : " .. actualOutput)
        print("-------------------------")
        emu.stop(1)
    else
        emu.displayMessage("PASSED", "Test passed")
        print("TEST PASSED: " .. ROMName)
        emu.stop(0)
    end
end

-- If an error has been signaled, check to make sure that it is indeed
-- the expected behavior.
function onErrorSignaled()
    if expectedOutput == "'err" then
        emu.displayMessage("PASSED", "Test passed")
        emu.stop(0)
    else
        emu.displayMessage("FAILURE", "result was an error")
        print("-------------------------")
        print("TEST FAILED: " .. ROMName)
        print("An error was signaled.")
        print("  Expected: " .. expectedOutput)
        print("-------------------------")
        emu.stop(1)
    end
end

-- Fail the test for taking too long
function timeoutFail()
    if emu.getState()["frameCount"] > TEST_MAX_TIME then
        emu.displayMessage("FAILURE", "Test took too long")
        print("-------------------------")
        print("TEST FAILED: " .. ROMName)
        print("Test took too long to run.")
        print("-------------------------")
        -- stop things
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

emu.displayMessage("TESTING", ROMName)

-- set up testing environment and callbacks
loadTestExpectations()
noErr = emu.addMemoryCallback(onFinished, emu.callbackType.write, 0x002000)
error = emu.addMemoryCallback(onErrorSignaled, emu.callbackType.write, 0x002001)
timeout = emu.addEventCallback(timeoutFail, emu.eventType.startFrame)

