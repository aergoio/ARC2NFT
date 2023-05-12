------------------------------------------------------------------------------
-- Aergo Standard NFT Interface (Proposal) - 20210425
------------------------------------------------------------------------------

extensions["approval"] = true

state.var {
  _operatorApprovals = state.map()  -- address/address -> bool
}

-- Approve an account to operate on the given non-fungible token.
-- Use `nil` on the operator to remove the approval
-- @type    call
-- @param   operator    (address) the new approved NFT controller
-- @param   tokenId     (str128) the NFT token to be controlled
-- @event   approve(owner, operator, tokenId)
function approve(operator, tokenId)
  _typecheck(tokenId, 'str128')
  if operator ~= nil then
    operator = _typecheck(operator, 'address')
  end

  local token = _tokens[tokenId]
  assert(token ~= nil, "ARC2: approve - nonexisting token")
  local owner = token["owner"]

  assert(not _paused:get(), "ARC2: paused contract")
  assert(not _blacklist[owner], "ARC2: owner is on blacklist")
  if operator ~= nil then
    assert(not _blacklist[operator], "ARC2: operator is on blacklist")
  end

  assert(owner ~= operator, "ARC2: approve - to current owner")
  local sender = system.getSender()
  assert(sender == owner or isApprovedForAll(owner, sender),
    "ARC2: approve - caller is not owner nor approved for all")

  token["approved"] = operator
  _tokens[tokenId] = token

  contract.event("approve", owner, operator, tokenId)
end

-- Get the approved operator address for a given non-fungible token
-- @type    query
-- @param   tokenId  (str128) the NFT token to find the approved operator
-- @return  (address) the approved operator address for this NFT, or nil if there is none
function getApproved(tokenId)
  _typecheck(tokenId, 'str128')
  local token = _tokens[tokenId]
  assert(token ~= nil, "ARC2: getApproved - nonexisting token")
  return token["approved"]
end

-- Allow an operator to control all the sender's tokens
-- @type    call
-- @param   operator  (address) the operator address
-- @param   approved  (boolean) true if the operator is approved, false to revoke approval
-- @event   approvalForAll(owner, operator, approved)
function setApprovalForAll(operator, approved)
  operator = _typecheck(operator, 'address')
  _typecheck(approved, 'boolean')

  local owner = system.getSender()

  assert(not _paused:get(), "ARC2: paused contract")
  assert(not _blacklist[owner], "ARC2: owner is on blacklist")
  if approved then
    assert(not _blacklist[operator], "ARC2: operator is on blacklist")
  end

  assert(operator ~= owner, "ARC2: setApprovalForAll - to caller")

  _operatorApprovals[owner .. '/' .. operator] = approved

  contract.event("approvalForAll", owner, operator, approved)
end

-- Check if the given operator is approved to control the owner's tokens
-- @type    query
-- @param   owner       (address) owner address
-- @param   operator    (address) operator address
-- @return  (bool) true/false
function isApprovedForAll(owner, operator)
  return _operatorApprovals[owner .. '/' .. operator] or false
end


abi.register(approve, setApprovalForAll)
abi.register_view(getApproved, isApprovedForAll)
