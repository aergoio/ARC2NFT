------------------------------------------------------------------------------
-- Aergo Standard NFT Interface (Proposal) - 20210425
------------------------------------------------------------------------------

extensions["mintable"] = true

state.var {
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

  return (account == _contract_owner:get()) or (_minter[account] == true)
end

-- Add an account to the minters group
-- @type    call
-- @param   account  (address)
-- @event   addMinter(account)

function addMinter(account)
  _typecheck(account, 'address')

  local creator = _contract_owner:get()
  assert(system.getSender() == creator, "ARC2: only the contract owner can add a minter")
  assert(account ~= creator, "ARC2: the contract owner is always a minter")

  _minter[account] = true

  contract.event("addMinter", account)
end

-- Remove an account from the minters group
-- @type    call
-- @param   account  (address)
-- @event   removeMinter(account)

function removeMinter(account)
  _typecheck(account, 'address')

  local creator = _contract_owner:get()
  assert(system.getSender() == creator, "ARC2: only the contract owner can remove a minter")
  assert(account ~= creator, "ARC2: the contract owner is always a minter")
  assert(isMinter(account), "ARC2: not a minter")

  _minter:delete(account)

  contract.event("removeMinter", account)
end

-- Renounce the minter role
-- @type    call
-- @event   removeMinter(account)

function renounceMinter()
  local sender = system.getSender()
  assert(sender ~= _contract_owner:get(), "ARC2: contract owner can't renounce minter role")
  assert(isMinter(sender), "ARC2: only minter can renounce minter role")

  _minter:delete(sender)

  contract.event("removeMinter", sender)
end

-- Mint a new non-fungible token
-- @type    call
-- @param   to       (address) recipient's address
-- @param   tokenId  (str128) the non-fungible token id
-- @param   metadata (table) lua table containing key-value pairs
-- @param   ...      additional data, is sent unaltered in a call to 'nonFungibleReceived' on 'to'
-- @return  value returned from the 'nonFungibleReceived' callback, or nil
-- @event   mint(to, tokenId)

function mint(to, tokenId, metadata, ...)
  assert(isMinter(system.getSender()), "ARC2: only minter can mint")
  local max_supply = _max_supply:get()
  assert(not max_supply or (totalSupply() + 1) <= max_supply, "ARC2: TotalSupply is over MaxSupply")

  return _mint(to, tokenId, metadata, ...)
end

-- Retrieve the Max Supply
-- @type    query
-- @return  amount   (integer) the maximum amount of tokens that can be active on the contract

function maxSupply()
  return _max_supply:get() or 0
end

abi.register(mint, addMinter, removeMinter, renounceMinter)
abi.register_view(isMinter, maxSupply)
