------------------------------------------------------------------------------
-- Aergo Standard Non Fungible Token Interface (Proposal) - 20190806
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
  elseif (x and t == 'ubig') then
    -- check unsigned bignum
    assert(bignum.isbignum(x), string.format("invalid type: %s != %s", type(x), t))
    assert(x >= bignum.number(0), string.format("%s must be positive number", bignum.tostring(x)))
  else
    -- check default lua types
    assert(type(x) == t, string.format("invalid type: %s != %s", type(x), t or 'nil'))
  end
end

address0 = '1111111111111111111111111111111111111111111111111111'

state.var {
  _tokenOwner = state.map(), -- unsigned_bignum --> address
  _ownedTokenCount = state.map(), -- address -> unsigned_bignum
  _operatorApprovals = state.map(), -- address/address -> bool

  _name = state.value(),
  _symbol = state.value(),
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

local function _transfer(from, to, tokenId, ...)
  _typecheck(from, 'address')
  _typecheck(to, 'address')
  _typecheck(tokenId, 'ubig')

  assert(ownerOf(tokenId) == from, "invalid owner")
  
  _ownedTokenCount[from] = _ownedTokenCount[from] - 1
  _ownedTokenCount[to] = (_ownedTokenCount[to] or bignum.number(0)) + 1

  _tokenOwner[bignum.tostring(tokenId)] = to

  _callOnARC2Received(from, to, tokenId, ...)

  contract.event("transfer", from, to, tokenId)
end

local function _mint(to, tokenId, ...)
  _typecheck(to, 'address')
  _typecheck(tokenId, 'ubig')

  assert(_tokenOwner[bignum.tostring(tokenId)] == nil, "token is already minted")

  _tokenOwner[bignum.tostring(tokenId)] = to
  _ownedTokenCount[to] = (_ownedTokenCount[to] or bignum.number(0)) + 1

  _callOnARC2Received(address0, to, tokenId, ...)

  contract.event("transfer", address0, to, tokenId)
end

local function _burn(from, tokenId)
  _typecheck(from, 'address')
  _typecheck(tokenId, 'ubig')

  assert(ownerOf(tokenId) == from, "invalid owner")

  _ownedTokenCount[from] = _ownedTokenCount[from] - 1

  _tokenOwner[bignum.tostring(tokenId)] = address0 

  contract.event("transfer", from, address0, tokenId)
end

-- Count of all NFTs assigned to an owner
-- @type    query
-- @param   owner  (address) a target address
-- @return  (ubig) the number of NFT tokens of owner
function balanceOf(owner)
  return _ownedTokenCount[owner] or bignum.number(0)
end

-- Find the owner of an NFT
-- @type    query
-- @param   tokenId (ubig) the NFT id
-- @return (ubig) the address of the owner of the NFT
function ownerOf(tokenId) 
  local owner = _tokenOwner[bignum.tostring(tokenId)]
  assert(owner ~= nil, "token is not exist")
  assert(owner ~= address0, "token is burned")

  return owner
end

-- Transfer sender's token to target 'to'
-- @type    call
-- @param   to      (address) a target address
-- @param   tokenId (ubig) the NFT token to send
-- @param   ...     addtional data, MUST be sent unaltered in call to 'tokensReceived' on 'to'
-- @event   transfer(from, to, tokenId)
function transfer(to, tokenId, ...) 
  _transfer(system.getSender(), to, tokenId, ...)
end

-- Get allowance from owner to spender
-- @type    query
-- @param   owner       (address) owner's address
-- @param   operator    (address) allowed address
-- @return  (bool) true/false
function isApprovedForAll(owner, operator) 
  return _operatorApprovals[owner .."/"..operator]
end

-- Allow operator to use all sender's token
-- @type    call
-- @param   operator  (address) a operator's address
-- @param   approved  (boolean) true/false
-- @event   approve(owner, operator, approved)
function setApprovalForAll(operator, approved) 
  _typecheck(operator, 'address')
  _typecheck(approved, 'boolean')
  assert(system.getSender() ~= operator, "cannot set approve self as operator")

  _operatorApprovals[system.getSender().."/"..operator] = approved

  contract.event("approve", system.getSender(), operator, approved)
end

-- Transfer 'from's token to target 'to'.
-- Tx sender have to be approved to spend from 'from'
-- @type    call
-- @param   from    (address) a sender's address
-- @param   to      (address) a receiver's address
-- @param   tokenId   (ubig) an amount of token to send
-- @param   ...     addtional data, MUST be sent unaltered in call to 'tokensReceived' on 'to'
-- @event   transfer(from, to, tokenId)
function transferFrom(from, to, tokenId, ...)
  assert(isApprovedForAll(from, system.getSender()), "caller is not approved for holder")

  _transfer(from, to, tokenId, ...)
end

abi.register_view(balanceOf, ownerOf, isApprovedForAll)
abi.register(transfer, transferFrom, setApprovalForAll)

function constructor()
    _init("simpleNFT", "SYMNFT")    
end

function mint(tokenId)
    -- check existance
    _mint(system.getCreator(), tokenId)
end

function burn(tokenId)
    _burn(system.getSender(), tokenId)
end

function burnFrom(from, tokenId)
    assert(isApprovedForAll(from, system.getSender()), "caller is not approved for holder")

    _burn(from, tokenId)
end

abi.register(mint, burn, burnFrom)