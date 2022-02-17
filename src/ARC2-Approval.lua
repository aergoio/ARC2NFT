------------------------------------------------------------------------------
-- Aergo Standard NFT Interface (Proposal) - 20210425
------------------------------------------------------------------------------

extensions["approval"] = true


state.var {
  _operatorApprovals = state.map(), -- address/address -> bool
}


-- Approve `to` to operate on `tokenId`
-- Emits an approve event
local function _approve(to, tokenId)
  local token = _tokens[tokenId]
  local owner = token["owner"]
  assert(not _paused:get(), "ARC2: paused contract")
  assert(not _blacklist[owner], "ARC2: owner is on blacklist")
  if to == nil then
    table.remove(token, "approved")
  else
    assert(not _blacklist[to], "ARC2: user is on blacklist")
    token["approved"] = to
  end
  _tokens[tokenId] = token
  contract.event("approve", owner, to, tokenId)
end


-- Change or reaffirm the approved address for an NFT
-- @type    call
-- @param   to          (address) the new approved NFT controller
-- @param   tokenId     (str128) the NFT token to approve
-- @event   approve(owner, to, tokenId)
function approve(to, tokenId)
  _typecheck(to, 'address')
  _typecheck(tokenId, 'str128')

  local owner = ownerOf(tokenId)
  assert(owner ~= nil, "ARC2: approve - nonexisting token")
  assert(owner ~= to, "ARC2: approve - to current owner")
  assert(system.getSender() == owner or isApprovedForAll(owner, system.getSender()), 
    "ARC2: approve - caller is not owner nor approved for all")

  _approve(to, tokenId)
end

-- Get the approved address for a single NFT
-- @type    query
-- @param   tokenId  (str128) the NFT token to find the approved address for
-- @return  (address) the approved address for this NFT, or nil
function getApproved(tokenId)
  _typecheck(tokenId, 'str128')
  local token = _tokens[tokenId]
  assert(token ~= nil, "ARC2: getApproved - nonexisting token")
  return token["approved"]
end


-- Allow operator to control all sender's token
-- @type    call
-- @param   operator  (address) a operator's address
-- @param   approved  (boolean) true if the operator is approved, false to revoke approval
-- @event   approvalForAll(owner, operator, approved)
function setApprovalForAll(operator, approved)
  _typecheck(operator, 'address')
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


-- Get allowance from owner to spender
-- @type    query
-- @param   owner       (address) owner's address
-- @param   operator    (address) allowed address
-- @return  (bool) true/false
function isApprovedForAll(owner, operator)
  return _operatorApprovals[owner .. '/' .. operator] or false
end


-- Transfer a token of 'from' to 'to'
-- @type    call
-- @param   from    (address) a sender's address
-- @param   to      (address) a receiver's address
-- @param   tokenId (str128) the NFT token to send
-- @param   ...     (Optional) addtional data, MUST be sent unaltered in call to 'onARC2Received' on 'to'
-- @event   transfer(from, to, tokenId)
function transferFrom(from, to, tokenId, ...)
  _typecheck(from, 'address')
  _typecheck(to, 'address')
  _typecheck(tokenId, 'str128')

  local owner = ownerOf(tokenId)
  assert(owner ~= nil, "ARC2: transferFrom - nonexisting token")
  assert(from == owner, "ARC2: transferFrom - transfer of token that is not own")

  local operator = system.getSender()
  assert(operator == owner or getApproved(tokenId) == operator or isApprovedForAll(owner, operator), "ARC2: transferFrom - caller is not owner nor approved")

  contract.event("transfer", from, to, tokenId, operator)

  return _transfer(from, to, tokenId, ...)
end


abi.register(approve, setApprovalForAll, transferFrom)
abi.register_view(getApproved, isApprovedForAll)
