------------------------------------------------------------------------------
-- Aergo Standard Token Interface (Proposal) - 20211028
-- Pausable
------------------------------------------------------------------------------

extensions["pausable"] = true

state.var {
  _pauser = state.map()    -- address -> boolean
}

-- Indicate whether an account has the pauser role
-- @type    query
-- @param   account  (address)
-- @return  (bool) true/false

function isPauser(account)
  _typecheck(account, 'address')

  return (account == system.getCreator()) or (_pauser[account]==true)
end

-- Grant the pauser role to an account
-- @type    call
-- @param   account  (address)
-- @event   addPauser(account)

function addPauser(account)
  _typecheck(account, 'address')

  assert(system.getSender() == system.getCreator(), "ARC2: only contract owner can approve pauser role")

  _pauser[account] = true

  contract.event("addPauser", account)
end

-- Removes the pauser role from an account
-- @type    call
-- @param   account  (address)
-- @event   removePauser(account)

function removePauser(account)
  _typecheck(account, 'address')

  assert(system.getSender() == system.getCreator(), "ARC2: only owner can remove pauser role")
  assert(isPauser(account), "ARC2: only pauser can be removed pauser role")

  _pauser[account] = nil

  contract.event("removePauser", account)
end

-- Renounce the granted pauser role
-- @type    call
-- @event   removePauser(account)

function renouncePauser()
  assert(system.getSender() ~= system.getCreator(), "ARC2: owner can't renounce pauser role")
  assert(isPauser(system.getSender()), "ARC2: only pauser can renounce pauser role")

  _pauser[system.getSender()] = nil

  contract.event("removePauser", system.getSender())
end

-- Indicate if the contract is paused
-- @type    query
-- @return  (bool) true/false

function paused()
  return (_paused:get() == true)
end

-- Put the contract in a paused state
-- @type    call
-- @event   pause(caller)

function pause()
  assert(not _paused:get(), "ARC2: contract is paused")
  assert(isPauser(system.getSender()), "ARC2: only pauser can pause")

  _paused:set(true)

  contract.event("pause", system.getSender())
end

-- Return the contract to the normal state
-- @type    call
-- @event   unpause(caller)

function unpause()
  assert(_paused:get(), "ARC2: contract is unpaused")
  assert(isPauser(system.getSender()), "ARC2: only pauser can unpause")

  _paused:set(false)

  contract.event("unpause", system.getSender())
end


abi.register(pause, unpause, removePauser, renouncePauser, addPauser)
abi.register_view(paused, isPauser)
