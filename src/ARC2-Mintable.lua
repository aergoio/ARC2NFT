------------------------------------------------------------------------------
-- Aergo Standard NFT Interface (Proposal) - 20210425
------------------------------------------------------------------------------

extensions["mintable"] = true

state.var {
  -- mintable
  _minter = state.map(),       -- address -> boolean
  _max_supply = state.value()  -- integer
}

-- set Max Supply
-- @type    internal
-- @param   amount   (integer) amount of mintable tokens

local function _setMaxSupply(amount)
  _typecheck(amount, 'uint')
  _max_supply:set(amount)
end

-- Indicate if an account is a minter
-- @type    query
-- @param   account  (address)
-- @return  (bool) true/false

function isMinter(account)
  _typecheck(account, 'address')

  return (account == system.getCreator()) or (_minter[account]==true)
end

-- Add an account to minters
-- @type    call
-- @param   account  (address)
-- @event   addMinter(account)

function addMinter(account)
  _typecheck(account, 'address')

  assert(system.getSender() == system.getCreator(), "ARC2: only the contract owner can add a minter")

  _minter[account] = true

  contract.event("addMinter", account)
end

-- Remove an account from minters
-- @type    call
-- @param   account  (address)
-- @event   removeMinter(account)

function removeMinter(account)
  _typecheck(account, 'address')

  assert(system.getSender() == system.getCreator(), "ARC2: only the contract owner can remove a minter")
  assert(account ~= system.getCreator(), "ARC2: the contract owner is always a minter")
  assert(isMinter(account), "ARC2: not a minter")

  _minter:delete(account)

  contract.event("removeMinter", account)
end

-- Renounce the Minter Role of TX sender
-- @type    call
-- @event   removeMinter(TX sender)

function renounceMinter()
  local sender = system.getSender()
  assert(sender ~= system.getCreator(), "ARC2: contract owner can't renounce minter role")
  assert(isMinter(sender), "ARC2: only minter can renounce minter role")

  _minter:delete(sender)

  contract.event("removeMinter", sender)
end

-- Mint a new non-fungible token
-- @type    call
-- @param   to       (address) recipient's address
-- @param   tokenId  (str128) the NFT id
-- @param   ...      additional data, is sent unaltered in call to 'tokensReceived' on 'to'
-- @return  value returned from 'tokensReceived' callback, or nil
-- @event   mint(to, tokenId)

function mint(to, tokenId, ...)
  assert(isMinter(system.getSender(), "ARC2: only minter can mint")
  assert(not _max_supply:get() or (totalSupply() + 1) <= _max_supply:get(), "ARC2: totalSupply is over MaxSupply")

  return _mint(to, tokenId, ...)
end

-- return Max Supply
-- @type    query
-- @return  amount   (integer) amount of tokens to mint

function maxSupply()
  return _max_supply:get() or 0
end

abi.register(mint, addMinter, removeMinter, renounceMinter)
abi.register_view(isMinter, maxSupply)
