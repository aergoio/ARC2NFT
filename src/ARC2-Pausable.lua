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

  return (account == system.getCreator()) or (_pauser[account] == true)
end

-- Grant the pauser role to an account
-- @type    call
-- @param   account  (address)
-- @event   addPauser(account)

function addPauser(account)
  _typecheck(account, 'address')

  assert(system.getSender() == system.getCreator(), "ARC2: only contract owner can grant pauser role")

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
  assert(_pauser[account] == true, "ARC2: account does not have pauser role")

  _pauser[account] = nil

  contract.event("removePauser", account)
end

-- Renounce the granted pauser role
-- @type    call
-- @event   removePauser(account)

function renouncePauser()
  local sender = system.getSender()
  assert(sender ~= system.getCreator(), "ARC2: owner can't renounce pauser role")
  assert(_pauser[sender] == true, "ARC2: account does not have pauser role")

  _pauser[sender] = nil

  contract.event("removePauser", sender)
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
  local sender = system.getSender()
  assert(not _paused:get(), "ARC2: contract is paused")
  assert(isPauser(sender), "ARC2: only pauser can pause")

  _paused:set(true)

  contract.event("pause", sender)
end

-- Return the contract to the normal state
-- @type    call
-- @event   unpause(caller)

function unpause()
  local sender = system.getSender()
  assert(_paused:get(), "ARC2: contract is unpaused")
  assert(isPauser(sender), "ARC2: only pauser can unpause")

  _paused:set(false)

  contract.event("unpause", sender)
end


abi.register(pause, unpause, removePauser, renouncePauser, addPauser)
abi.register_view(paused, isPauser)
