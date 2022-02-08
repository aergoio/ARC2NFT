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
    assert(#x <= 128, string.format("too long str128 length: %s", #x))
  elseif (x and t == 'uint') then
    -- check unsigned integer
    assert(type(x) == 'number', string.format("invalid type: %s != number", type(x)))
    assert(math.floor(x) == x, "the number must be an integer")
    assert(x >= 0, "the number must be 0 or positive")
  else
    -- check default lua types
    assert(type(x) == t, string.format("invalid type: %s != %s", type(x), t or 'nil'))
  end
end

address0 = '1111111111111111111111111111111111111111111111111111'


state.var {
  _name = state.value(),            -- string
  _symbol = state.value(),          -- string

  _num_burned = state.value(),      -- integer
  _last_index = state.value(),      -- integer
  _ids = state.map(),               -- integer -> str128
  _tokens = state.map(),            -- str128 -> { owner: address, approved: address }
  _balances = state.map(),          -- address -> integer

  -- Pausable
  _paused = state.value(),          -- boolean

  -- Blacklist
  _blacklist = state.map()          -- address -> boolean
}


-- call this at constructor
local function _init(name, symbol)
  _typecheck(name, 'string')
  _typecheck(symbol, 'string')
  
  _name:set(name)
  _symbol:set(symbol)

  _last_index:set(0)
  _num_burned:set(0)

  _paused:set(false)
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
-- @return  (integer) the number of NFT tokens of owner
function balanceOf(owner)
  return _balances[owner] or 0
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

  assert(not _paused:get(), "ARC2: paused contract")
  assert(not _blacklist[to], "ARC2: recipient is on blacklist")

  assert(not _exists(tokenId), "ARC2: mint - already minted token")

  local index = _last_index:get() + 1
  _last_index:set(index)
  _ids[tostring(index)] = tokenId

  local token = {
    owner = to
  }
  _tokens[tokenId] = token

  _balances[to] = (_balances[to] or 0) + 1

  contract.event("mint", to, tokenId)

  return _callOnARC2Received(nil, to, tokenId, ...)
end


local function _burn(tokenId)
  _typecheck(tokenId, 'str128')

  local owner = ownerOf(tokenId)

  assert(not _paused:get(), "ARC2: paused contract")
  assert(not _blacklist[owner], "ARC2: owner is on blacklist")

  local index,_ = findToken({contains=tokenId}, 0)
  assert(index ~= nil and index > 0, "burn: token not found")
  -- _ids[tostring(index)] = nil
  _ids:delete(tostring(index))

  _tokens:delete(tokenId)
  _balances[owner] = _balances[owner] - 1

  _num_burned:set(_num_burned:get() + 1)

  contract.event("burn", owner, tokenId)
end


local function _transfer(from, to, tokenId, ...)
  assert(not _paused:get(), "ARC2: paused contract")
  assert(not _blacklist[from], "ARC2: sender is on blacklist")
  assert(not _blacklist[to], "ARC2: recipient is on blacklist")

  _balances[from] = _balances[from] - 1
  _balances[to] = (_balances[to] or 0) + 1

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
  assert(owner ~= nil, "ARC2: transfer - nonexisting token")
  assert(from == owner, "ARC2: transfer of token that is not own")

  contract.event("transfer", from, to, tokenId, nil)

  return _transfer(from, to, tokenId, ...)
end


function burn(tokenId)
  _typecheck(tokenId, 'str128')

  local owner = ownerOf(tokenId)
  assert(owner ~= nil, "ARC2: burn - nonexisting token")
  assert(system.getSender() == owner, "ARC2: cannot burn a token that is not own")

  _burn(tokenId)
end


function totalSupply()
  return _last_index:get() - _num_burned:get()
end

function nextToken(prev_index)
  _typecheck(prev_index, 'uint')

  local index = prev_index
  local last_index = _last_index:get()
  local tokenId

  if index >= last_index then
    return nil, nil
  end

  do
    index = index + 1
    tokenId = _ids[tostring(index)]
  while tokenId == nil and index < last_index

  if index == last_index and tokenId == nil then
    index = nil
  end

  return index, tokenId
end

-- retrieve the first token found that mathes the query
-- the query is a table that can contain these fields:
--   owner    - the owner of the token (address)
--   contains - check if the tokenId contains this string
--   pattern  - check if the tokenId matches this Lua regex pattern
-- the prev_index must be 0 in the first call
-- for the next calls, just inform the returned index from the last call
-- return value: 2 variables: index and tokenId
-- if no token is found with the given query, it returns (nil, nil)
function findToken(query, prev_index)
  _typecheck(query, 'table')
  _typecheck(prev_index, 'uint')

  local contains = query["contains"]
  if contains then
    query["pattern"] = escape(contains)
  end

  local index = prev_index
  local last_index = _last_index:get()
  local tokenId, owner

  if index >= last_index then
    return nil, nil
  end

  do
    index = index + 1
    tokenId = _ids[tostring(index)]
    if not token_matches(tokenId, query) then
      tokenId = nil
    end
  while tokenId == nil and index < last_index

  if index == last_index and tokenId == nil then
    index = nil
  end

  return index, tokenId
end

local function token_matches(tokenId, query)

  if tokenId == nil then
    return false
  end

  local user = query["owner"]
  local pattern = query["pattern"]

  if user then
    local owner = ownerOf(tokenId)
    if owner ~= user then
      return false
    end
  end

  if pattern then
    if not tokenId:match(pattern) then
      return false
    end
  end

  return true
end

local function escape(str)
  return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", function(c) return "%" .. c end)
end

abi.register(transfer, burn)
abi.register_view(name, symbol, balanceOf, ownerOf, totalSupply, nextToken, findToken)
