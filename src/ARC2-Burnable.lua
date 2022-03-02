------------------------------------------------------------------------------
-- Aergo Standard NFT Interface (Proposal) - 20210425
------------------------------------------------------------------------------

extensions["burnable"] = true

-- Burn a non-fungible token
-- @type    call
-- @param   tokenId  (str128) the identifier of the token to be burned
-- @event   burn(owner, tokenId)
function burn(tokenId)
  _typecheck(tokenId, 'str128')

  local owner = ownerOf(tokenId)
  assert(owner ~= nil, "ARC2: burn - nonexisting token")
  assert(system.getSender() == owner, "ARC2: cannot burn a token that is not own")

  _burn(tokenId)
end

abi.register(burn)
