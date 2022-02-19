------------------------------------------------------------------------------
-- Aergo Standard NFT Interface (Proposal) - 20210425
------------------------------------------------------------------------------

extensions = {}

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
  _tokens = state.map(),            -- str128 -> { index: integer, owner: address, approved: address }
  _user_tokens = state.map(),       -- address -> array of integers (index to tokenId)

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

-- Count of all NFTs
-- @type    query
-- @return  (integer) the number of non-fungible tokens on this contract
function totalSupply()
  return _last_index:get() - _num_burned:get()
end

-- Count of all NFTs assigned to an owner
-- @type    query
-- @param   owner  (address) a target address
-- @return  (integer) the number of NFT tokens of owner
function balanceOf(owner)
  local list = _user_tokens[owner] or {}
  return #list
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


local function add_to_owner(index, owner)
  local list = _user_tokens[owner] or {}
  table.insert(list, index)
  _user_tokens[owner] = list
end

local function remove_from_owner(index, owner)
  local list = _user_tokens[owner] or {}
  for position,value in ipairs(list) do
    if value == index then
      table.remove(list, position)
      break
    end
  end
  if #list > 0 then
    _user_tokens[owner] = list
  else
    _user_tokens:delete(owner)
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
    index = index,
    owner = to
  }
  _tokens[tokenId] = token

  add_to_owner(index, to)

  contract.event("mint", to, tokenId)

  return _callOnARC2Received(nil, to, tokenId, ...)
end


local function _burn(tokenId)
  _typecheck(tokenId, 'str128')

  local token = _tokens[tokenId]
  assert(token ~= nil, "ARC2: burn: token not found")
  local index = token["index"]
  local owner = token["owner"]

  assert(not _paused:get(), "ARC2: paused contract")
  assert(not _blacklist[owner], "ARC2: owner is on blacklist")

  _ids:delete(tostring(index))

  _tokens:delete(tokenId)

  remove_from_owner(index, owner)

  _num_burned:set(_num_burned:get() + 1)

  contract.event("burn", owner, tokenId)
end


local function _transfer(from, to, tokenId, ...)
  assert(not _paused:get(), "ARC2: paused contract")
  assert(not _blacklist[from], "ARC2: sender is on blacklist")
  assert(not _blacklist[to], "ARC2: recipient is on blacklist")

  local token = _tokens[tokenId]
  token["owner"] = to
  table.remove(token, "approved")  -- clear approval
  _tokens[tokenId] = token

  local index = token["index"]
  remove_from_owner(index, from)
  add_to_owner(index, to)

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

  local token = _tokens[tokenId]
  assert(token ~= nil, "ARC2: transfer - nonexisting token")

  assert(extensions["non_transferable"] == nil, "ARC2: this token is non-transferable")

  local sender = system.getSender()
  local owner = token["owner"]
  assert(sender == owner, "ARC2: transfer of token that is not own")

  contract.event("transfer", sender, to, tokenId, nil)

  return _transfer(sender, to, tokenId, ...)
end



-- Token List Functions --

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

  if tokenId == nil then
    index = nil
  end

  return index, tokenId
end

function tokenFromUser(user, position)
  _typecheck(user, 'address')
  _typecheck(position, 'uint')

  local list = _user_tokens[user] or {}
  local index = list[position]
  local tokenId = _ids[tostring(index)]
  return tokenId
end


-- returns a JSON string containing the list of ARC2 extensions
-- that were included on the contract
function arc2_extensions()
  local list = {}
  for name,_ in pairs(extensions) do
    table.insert(list, name)
  end
  return json.encode(list)
end


abi.register(transfer, arc2_extensions)
abi.register_view(name, symbol, balanceOf, ownerOf, totalSupply, nextToken, tokenFromUser)
