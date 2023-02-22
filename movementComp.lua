local vec2 = require("vec2")
local lMath = require("lmath")
local gravityComp = require("gravityComp")
local jumpComp = require("jumpComp")
local directionComp = require("directionComp")

local moveComp = {
    MoveVelocity = vec2.new(0.0, 0.0),
    DirectionComp = directionComp,
    GravityComp = gravityComp,
    JumpComp = jumpComp,
    MoveForce = 0.0
}

local jumpForce = 0.0
local gravForce = 0.0
local moveForce = 0.0

--HORIZONTAL MOVEMENT
function moveComp.MoveInDirection(dt)
    if directionComp.IsRecivingInput == false then
        local decelSpeed = 0
        if gravityComp.IsGrounded == true then
            decelSpeed = directionComp.DecelerationSpeed
        else
            decelSpeed = directionComp.DecelerationSpeed * 0.25
        end

        local reductionForce = (directionComp.Dir * -1) * decelSpeed * dt
        local resultForce = reductionForce + moveForce

        local isPositiveDir = directionComp.Dir > 0
        local isNewVelocityLess = moveForce + resultForce < 0.0

        if (isPositiveDir and isNewVelocityLess) or (not isPositiveDir and not isNewVelocityLess) then
            moveForce = 0.0
        else
            moveForce = moveForce + reductionForce
        end
    else
        local newStep = 0.0
        if directionComp.IsRecivingInput then
            newStep = dt * directionComp.Dir * directionComp.AccelerationSpeed
        end

        moveForce = moveForce + newStep

        local isRightDir = directionComp.Dir > 0
        local isVelocityLeft = moveForce < 0.0
        if (isRightDir and isVelocityLeft) or (not isRightDir and not isVelocityLeft)then
            moveForce = moveForce *-1
        end


    end
    moveForce=lMath.clamp(moveForce,-1.0,1.0)
    moveComp.MoveForce = moveForce
    moveComp.MoveVelocity.x = moveForce * directionComp.MaxMoveSpeed
end

--JUMPING
function moveComp.ExtendJumpWithHeldButton(jumpInput, dt)
    local jComp = moveComp.JumpComp
    if jumpInput == false then
        return
    elseif jComp.JumpButtonHoldTimer >= jComp.MaxJumpButtonHoldTimer then
        return
    else
        local temp = jComp.JumpButtonHoldTimer + (dt * 0.7)
        jComp.JumpButtonHoldTimer = lMath.clamp(temp, 0.0, jComp.MaxJumpButtonHoldTimer)
        jComp.JumpTimer = jComp.JumpTimer + ((dt + jComp.JumpButtonHoldTimer) * 0.2);
        moveComp.JumpComp = jComp
    end
end

function moveComp.JumpingAndFalling(positionY, sizeY, dt)
    local gravComp = moveComp.GravityComp
    local jComp = moveComp.JumpComp

    if jComp.JumpTimer > 0.0 then
        local jumpMagnitude = -gravComp.Gravity * dt * ((jComp.JumpTimer * 4) ^ 2);

        jumpForce = jumpMagnitude

        jComp.JumpTimer = lMath.clamp(jComp.JumpTimer - dt, 0.0, jComp.MaxJumpTimer) --clamp this between 0 and max
    elseif gravComp.IsGrounded == false then
        gravComp.FallMomentum = gravComp.FallMomentum + (dt * gravComp.Weight)
        local gravityStep = gravComp.Gravity * gravComp.FallMomentum * dt
        gravForce = gravityStep
    else
        gravForce = 0.0
        jumpForce = 0.0
    end

    moveComp.MoveVelocity.y = jumpForce + gravForce
    moveComp.GravityComp = gravComp
    moveComp.JumpComp = jComp
end

function moveComp.InitiateJump()
    moveComp.JumpComp.JumpTimer = moveComp.JumpComp.MaxJumpTimer
    moveComp.JumpComp.JumpButtonHoldTimer = 0.0
    moveComp.GravityComp.FallMomentum = 0
    moveComp.GravityComp.IsGrounded = false
    gravForce = 0.0
    jumpForce = 0.0
end

function moveComp.BecomeGrounded()
    moveComp.MoveVelocity.y = 0
    moveComp.JumpComp.JumpTimer = 0
    moveComp.GravityComp.FallMomentum = 0
    moveComp.GravityComp.IsGrounded = true
end

return moveComp
