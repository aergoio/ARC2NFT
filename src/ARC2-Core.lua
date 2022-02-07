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

  _tokens = state.map()             -- str128 -> { owner: address, approved: address }
  _balances = state.map(),          -- address -> unsigned_bignum
}


-- call this at constructor
local function _init(name, symbol)
  _typecheck(name, 'string')
  _typecheck(symbol, 'string')
  
  _name:set(name)
  _symbol:set(symbol)
end

local function _callOnARC2Received(from, to, tokenId, ...)
  if system.isContract(to) then
    contract.call(to, "onARC2Received", system.getSender(), from, tokenId, ...)
  end
end

local function _exists(tokenId)
  return _tokens[tokenId] ~= nil
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
  return _balances[owner] or bignum.number(0)
end

-- Find the owner of an NFT
-- @type    query
-- @param   tokenId (str128) the NFT id
-- @return  (address) the address of the owner of the NFT, or nil if token does not exist
function ownerOf(tokenId)
  local token = _tokens[tokenId]
  if token == nil then
    return nil
  else
    return token["owner"]
  end
end



local function _mint(to, tokenId, ...)
  _typecheck(to, 'address')
  _typecheck(tokenId, 'str128')

  assert(not _exists(tokenId), "ARC2: mint - already minted token")

  local token = {
    owner = to
  }
  _tokens[tokenId] = token

  _balances[to] = (_balances[to] or bignum.number(0)) + 1

  contract.event("mint", to, tokenId)

  return _callOnARC2Received(nil, to, tokenId, ...)
end


local function _burn(tokenId)
  _typecheck(tokenId, 'str128')

  local owner = ownerOf(tokenId)

  _tokens:delete(tokenId)
  _balances[owner] = _balances[owner] - 1

  contract.event("burn", owner, tokenId)
end


local function _transfer(from, to, tokenId, ...)

  _balances[from] = _balances[from] - 1
  _balances[to] = (_balances[to] or bignum.number(0)) + 1

--[[
  local token = _tokens[tokenId]
  token["owner"] = to
  table.remove(token, "approved")  -- clear approval
  _tokens[tokenId] = token
]]

  -- this will also clear approvals from the previous owner
  local token = {
    owner = to
  }
  _tokens[tokenId] = token

  return _callOnARC2Received(from, to, tokenId, ...)
end


-- Transfer a token
-- @type    call
-- @param   to      (address) a receiver's address
-- @param   tokenId (str128) the NFT token to send
-- @param   ...     (Optional) addtional data, MUST be sent unaltered in call to 'onARC2Received' on 'to'
-- @event   transfer(from, to, tokenId)
function transfer(to, tokenId, ...)
  _typecheck(to, 'address')
  _typecheck(tokenId, 'str128')

  local from = system.getSender()

  local owner = ownerOf(tokenId)
  assert(owner ~= nil, "ARC2: safeTransferFrom - nonexisting token")
  assert(from == owner, "ARC2: safeTransferFrom - transfer of token that is not own")

  contract.event("transfer", nil, from, to, tokenId)

  return _transfer(from, to, tokenId, ...)
end


function burn(tokenId)
  _typecheck(tokenId, 'str128')

  local owner = ownerOf(tokenId)
  assert(owner ~= nil, "ARC2: burn - nonexisting token")
  assert(system.getSender() == owner, "ARC2: cannot burn a token that is not own")

  _burn(tokenId)
end


abi.register(transfer, burn)
abi.register_view(name, symbol, balanceOf, ownerOf)
