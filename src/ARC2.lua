------------------------------------------------------------------------------
-- Aergo Standard NFT Interface (Proposal) - 20210425
------------------------------------------------------------------------------

-- A internal type check function
-- @type internal
-- @param x variable to check
-- @param t (string) expected type
local function _typecheck(x, t)
  if (x and t == 'address') then
    assert(type(x) == 'string', "address must be string type")
    -- check address length
    assert(52 == #x, string.format("invalid address length: %s (%s)", x, #x))
    -- check character
    local invalidChar = string.match(x, '[^123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz]')
    assert(nil == invalidChar, string.format("invalid address format: %s contains invalid char %s", x, invalidChar or 'nil'))
  elseif (x and t == 'str128') then
    assert(type(x) == 'string', "str128 must be string type")
    -- check address length
    assert(128 >= #x, string.format("too long str128 length: %s", #x))
  else
    -- check default lua types
    assert(type(x) == t, string.format("invalid type: %s != %s", type(x), t or 'nil'))
  end
end

address0 = '1111111111111111111111111111111111111111111111111111'

  
state.var {
  _name = state.value(),            -- string
  _symbol = state.value(),          -- string

  _owners = state.map(),            -- str128 -> address
  _balances = state.map(),          -- address -> unsigned_bignum

  _tokenApprovals = state.map(),    -- str128 -> address
  _operatorApprovals = state.map(), -- address/address -> bool
}


-- call this at constructor
local function _init(name, symbol)
  _typecheck(name, 'string')
  _typecheck(symbol, 'string')
  
  _name:set(name)
  _symbol:set(symbol)
end

local function _callOnARC2Received(from, to, tokenId, ...)
  if to ~= address0 and system.isContract(to) then
    contract.call(to, "onARC2Received", system.getSender(), from, tokenId, ...)
  end
end

local function _exists(tokenId)
  owner = _owners[tokenId] or address0
  return owner ~= address0
end

-- Get the token name
-- @type    query
-- @return  (string) name of this token
function name()
  return _name:get()
end

-- Get the token symbol
-- @type    query
-- @return  (string) symbol of this token
function symbol()
  return _symbol:get()
end

-- Count of all NFTs assigned to an owner
-- @type    query
-- @param   owner  (address) a target address
-- @return  (ubig) the number of NFT tokens of owner
function balanceOf(owner)
  assert(owner ~= address0, "ARC2: balanceOf - query for zero address")
  return _balances[owner] or bignum.number(0)
end

-- Find the owner of an NFT
-- @type    query
-- @param   tokenId (str128) the NFT id
-- @return  (address) the address of the owner of the NFT
function ownerOf(tokenId)
  owner = _owners[tokenId] or address0
  assert(owner ~= address0, "ARC2: ownerOf - query for nonexistent token")
  return owner
end



local function _mint(to, tokenId)
  _typecheck(to, 'address')
  _typecheck(tokenId, 'str128')

  assert(to ~= address0, "ARC2: mint - to the zero address")
  assert(not _exists(tokenId), "ARC2: mint - already minted token")
  
  _balances[to] = (_balances[to] or bignum.number(0)) + 1
  _owners[tokenId] = to
  
  contract.event("transfer", address0, to, tokenId)
end


local function _burn(tokenId)
  _typecheck(tokenId, 'str128')

  owner = ownerOf(tokenId)
  
  -- Clear approvals from the previous owner
  _approve(address0, tokenId)

  _balances[owner] = _balances[owner] - 1
  _owners[tokenId] = nil

  contract.event("transfer", owner, address0, tokenId)
end


-- Approve `to` to operate on `tokenId`
-- Emits an approve event
local function _approve(to, tokenId)
  if to == address0 then
    _tokenApprovals:delete(tokenId)
  else
    _tokenApprovals[tokenId] = to
  end
  contract.event("approve", ownerOf(tokenId), to, tokenId)
end


-- Transfer a token of 'from' to 'to'
-- @type    call
-- @param   from    (address) a sender's address
-- @param   to      (address) a receiver's address
-- @param   tokenId (str128) the NFT token to send
-- @param   ...     (Optional) addtional data, MUST be sent unaltered in call to 'onARC2Received' on 'to'
-- @event   transfer(from, to, value)
function safeTransferFrom(from, to, tokenId, ...) 
  _typecheck(from, 'address')
  _typecheck(to, 'address')
  _typecheck(tokenId, 'str128')

  assert(_exists(tokenId), "ARC2: safeTransferFrom - nonexisting token")
  owner = ownerOf(tokenId)
  assert(owner == from, "ARC2: safeTransferFrom - transfer of token that is not own")
  assert(to ~= address0, "ARC2: safeTransferFrom - transfer to the zero address")

  spender = system.getSender()
  assert(spender == owner or getApproved(tokenId) == spender or isApprovedForAll(owner, spender), "ARC2: safeTransferFrom - caller is not owner nor approved")

  -- Clear approvals from the previous owner
  _approve(address0, tokenId)

  _balances[from] = _balances[from] - 1
  _balances[to] = (_balances[to] or bignum.number(0)) + 1
  _owners[tokenId] = to
  
  _callOnARC2Received(from, to, tokenId, ...)

  contract.event("transfer", from, to, tokenId)
end


-- Change or reaffirm the approved address for an NFT
-- @type    call
-- @param   to          (address) the new approved NFT controller
-- @param   tokenId     (str128) the NFT token to approve
-- @event   approve(owner, to, tokenId)
function approve(to, tokenId)
  _typecheck(to, 'address')
  _typecheck(tokenId, 'str128')

  owner = ownerOf(tokenId)
  assert(owner ~= to, "ARC2: approve - to current owner")
  assert(system.getSender() == owner or isApprovedForAll(owner, system.getSender()), 
    "ARC2: approve - caller is not owner nor approved for all")

  _approve(to, tokenId)
end

-- Get the approved address for a single NFT
-- @type    query
-- @param   tokenId  (str128) the NFT token to find the approved address for
-- @return  (address) the approved address for this NFT, or the zero address if there is none
function getApproved(tokenId) 
  _typecheck(tokenId, 'str128')
  assert(_exists(tokenId), "ARC2: getApproved - nonexisting token")

  return _tokenApprovals[tokenId] or address0
end


-- Allow operator to control all sender's token
-- @type    call
-- @param   operator  (address) a operator's address
-- @param   approved  (boolean) true if the operator is approved, false to revoke approval
-- @event   approvalForAll(owner, operator, approved)
function setApprovalForAll(operator, approved) 
  _typecheck(operator, 'address')
  _typecheck(approved, 'boolean')

  assert(operator ~= system.getSender(), "ARC2: setApprovalForAll - to caller")
  _operatorApprovals[system.getSender() .. '/' .. operator] = approved

  contract.event("approvalForAll", system.getSender(), operator, approved)
end


-- Get allowance from owner to spender
-- @type    query
-- @param   owner       (address) owner's address
-- @param   operator    (address) allowed address
-- @return  (bool) true/false
function isApprovedForAll(owner, operator) 
  return _operatorApprovals[owner .. '/' .. operator] or false
end


abi.register(setApprovalForAll, safeTransferFrom, approve)
abi.register_view(name, symbol, balanceOf, ownerOf, getApproved, isApprovedForAll) 
