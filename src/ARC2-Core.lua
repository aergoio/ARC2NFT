------------------------------------------------------------------------------
-- Aergo Standard NFT Interface (Proposal) - 20210425
------------------------------------------------------------------------------

extensions = {}

address0 = '1111111111111111111111111111111111111111111111111111'

-- A internal type check function
-- @type internal
-- @param x variable to check
-- @param t (string) expected type
local function _typecheck(x, t)
  if (x and t == 'address') then
    assert(type(x) == 'string', "address must be string type")
    -- check address length
    assert(52 == #x, string.format("invalid address length: %s (%s)", x, #x))
    -- check address checksum
    if x ~= address0 then
      local success = pcall(system.isContract, x)
      assert(success, "invalid address: " .. x)
    end
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


state.var {
  _contract_owner = state.value(),  -- string

  _name = state.value(),            -- string
  _symbol = state.value(),          -- string

  _num_burned = state.value(),      -- integer
  _last_index = state.value(),      -- integer
  _ids = state.map(),               -- integer -> str128
  _tokens = state.map(),            -- str128 -> { index: integer, owner: address, approved: address }

  -- Owner List / Enumerable
  _owner_token_count = state.map(), -- address -> integer
  _owner_tokens = state.map(2),     -- address, integer -> integer (index to tokenId)
  _owner_token_position = state.map(), -- integer -> integer

  -- Pausable
  _paused = state.value(),          -- boolean

  -- Blacklist
  _blacklist = state.map()          -- address -> boolean
}


-- call this at constructor
local function _init(name, symbol, owner)
  _typecheck(name, 'string')
  _typecheck(symbol, 'string')

  if owner == nil or owner == '' then
    owner = system.getCreator()
  elseif owner == 'none' then
    owner = nil
  else
    _typecheck(owner, "address")
  end
  _contract_owner:set(owner)

  _name:set(name)
  _symbol:set(symbol)

  _last_index:set(0)
  _num_burned:set(0)

  _paused:set(false)
end

local function _callReceiverCallback(from, to, tokenId, ...)
  if to ~= address0 and system.isContract(to) then
    return contract.call(to, "nonFungibleReceived", system.getSender(), from, tokenId, ...)
  else
    return nil
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
-- @return  (integer) the number of non-fungible tokens of owner
function balanceOf(owner)
  return _owner_token_count[owner] or 0
end

-- Find the owner of an NFT
-- @type    query
-- @param   tokenId  (str128) the non-fungible token id
-- @return  (address) the address of the owner, or nil if the token does not exist
function ownerOf(tokenId)
  local token = _tokens[tokenId]
  if token == nil then
    return nil
  else
    return token["owner"]
  end
end


local function add_to_owner(index, owner)
  local count = _owner_token_count[owner] or 0
  count = count + 1
  _owner_token_count[owner] = count
  _owner_tokens[owner][tostring(count)] = index
  _owner_token_position[index] = count
end

local function remove_from_owner(index, owner)
  local position = _owner_token_position[index]
  local count = _owner_token_count[owner]

  if position < count then
    local lastToken = _owner_tokens[owner][tostring(count)]
    _owner_tokens[owner][tostring(position)] = lastToken
    _owner_token_position[lastToken] = position
  end

  _owner_token_count[owner] = count - 1
end


local function _mint(to, tokenId, metadata, ...)
  _typecheck(to, 'address')
  _typecheck(tokenId, 'str128')

  assert(not _paused:get(), "ARC2: paused contract")
  assert(not _blacklist[to], "ARC2: recipient is on blacklist")

  assert(not _exists(tokenId), "ARC2: mint - already minted token")
  assert(metadata==nil or type(metadata)=="table", "ARC2: invalid metadata")

  local index = _last_index:get() + 1
  _last_index:set(index)
  _ids[index] = tokenId

  local token = {
    index = index,
    owner = to
  }
  if metadata ~= nil then
    assert(extensions["metadata"], "ARC2: this token has no support for metadata")
    for key,value in pairs(metadata) do
      assert(not is_reserved_metadata(key), "ARC2: reserved metadata")
      token[key] = value
    end
  end
  _tokens[tokenId] = token

  add_to_owner(index, to)

  contract.event("mint", to, tokenId)

  return _callReceiverCallback(nil, to, tokenId, ...)
end


local function _burn(tokenId)
  _typecheck(tokenId, 'str128')

  local token = _tokens[tokenId]
  assert(token ~= nil, "ARC2: burn: token not found")
  local index = token["index"]
  local owner = token["owner"]

  assert(not _paused:get(), "ARC2: paused contract")
  assert(not _blacklist[owner], "ARC2: owner is on blacklist")

  _ids:delete(index)

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
  token["approved"] = nil   -- clear approval
  _tokens[tokenId] = token

  local index = token["index"]
  remove_from_owner(index, from)
  add_to_owner(index, to)

  return _callReceiverCallback(from, to, tokenId, ...)
end


-- Transfer a token
-- @type    call
-- @param   to      (address) the receiver address
-- @param   tokenId (str128) the NFT token to send
-- @param   ...     (Optional) additional data, is sent unaltered in a call to 'nonFungibleReceived' on 'to'
-- @return  value returned from the 'nonFungibleReceived' callback, or nil
-- @event   transfer(from, to, tokenId)
function transfer(to, tokenId, ...)
  _typecheck(to, 'address')
  _typecheck(tokenId, 'str128')

  local token = _tokens[tokenId]
  assert(token ~= nil, "ARC2: transfer - nonexisting token")

  assert(extensions["non_transferable"] == nil and
              token["non_transferable"] == nil, "ARC2: this token is non-transferable")

  local sender = system.getSender()
  local owner = token["owner"]
  assert(sender == owner, "ARC2: transfer of token that is not own")

  contract.event("transfer", sender, to, tokenId)

  return _transfer(sender, to, tokenId, ...)
end

-- Transfer a non-fungible token of 'from' to 'to'
-- @type    call
-- @param   from    (address) the owner address
-- @param   to      (address) the receiver address
-- @param   tokenId (str128) the non-fungible token to send
-- @param   ...     (Optional) additional data, is sent unaltered in a call to 'nonFungibleReceived' on 'to'
-- @return  value returned from the 'nonFungibleReceived' callback, or nil
-- @event   transfer(from, to, tokenId, operator)
function transferFrom(from, to, tokenId, ...)
  _typecheck(from, 'address')
  _typecheck(to, 'address')
  _typecheck(tokenId, 'str128')

  local token = _tokens[tokenId]
  assert(token ~= nil, "ARC2: transferFrom - nonexisting token")

  local owner = token["owner"]
  assert(from == owner, "ARC2: transferFrom - token is not from account")

  local operator = system.getSender()

  -- if recallable, the creator/issuer can transfer the token
  if extensions["mintable"] then
    operator_can_recall = isMinter(operator)
  else
    operator_can_recall = (operator == _contract_owner:get())
  end
  local is_recall = (extensions["recallable"] or token["recallable"]) and operator_can_recall

  if not is_recall then
    assert(extensions["approval"], "ARC2: approval extension not included")
    -- check allowance
    assert(operator == token["approved"] or isApprovedForAll(owner, operator),
           "ARC2: transferFrom - caller is not approved")
    -- check if it is a non-transferable token
    assert(extensions["non_transferable"] == nil and
                token["non_transferable"] == nil, "ARC2: this token is non-transferable")
  end

  contract.event("transfer", from, to, tokenId, operator)

  return _transfer(from, to, tokenId, ...)
end


-- Token Enumeration Functions --


-- Retrieves the next token in the contract
-- @type    query
-- @param   prev_index (integer) the index of the previous returned token. use `0` in the first call
-- @param   max_items (integer) the maximum number of items to return
-- @return  (index, tokenId) the index of the next token and its token id, or `nil,nil` if no more tokens
function nextToken(prev_index, max_items)
  _typecheck(prev_index, 'uint')
  if max_items == nil then
    max_items = 1
  else
    _typecheck(max_items, 'uint')
  end

  local index = prev_index
  local last_index = _last_index:get()
  local tokenId
  local tokens = {}
  local count = 0

  while count < max_items and index < last_index do
    index = index + 1
    tokenId = _ids[index]
    if tokenId ~= nil then
      count = count + 1
      tokens[count] = tokenId
    end
  end

  if tokenId == nil then
    index = nil
  end

  if max_items == 1 then
    return index, tokenId
  else
    return index, tokens
  end
end

-- Retrieves the token from the given user at the given position
-- @type    query
-- @param   user      (address) ..
-- @param   position  (integer) the position of the token in the incremental sequence
-- @param   max_items (integer) the maximum number of items to return
-- @return  tokenId   (str128) the token id, or `nil` if no more tokens on this account
function tokenFromUser(user, position, max_items)
  _typecheck(user, 'address')
  _typecheck(position, 'uint')
  if max_items == nil then
    max_items = 1
  else
    _typecheck(max_items, 'uint')
  end

  local total = _owner_token_count[user] or 0
  if position == 0 or position > total then
    return nil
  end

  local tokens = {}
  local count = 0

  while count < max_items and position <= total do
    local index = _owner_tokens[user][tostring(position)]
    local tokenId = _ids[index]
    count = count + 1
    tokens[count] = tokenId
    position = position + 1
  end

  if max_items == 1 then
    return tokens[1]
  else
    return tokens
  end
end


function set_contract_owner(address)
  assert(system.getSender() == _contract_owner:get(), "ARC2: permission denied")
  _typecheck(address, "address")
  _contract_owner:set(address)
end


-- Returns a JSON string containing the list of ARC2 extensions
-- that were included on the contract.
-- @type    query
function arc2_extensions()
  local list = {}
  for name,_ in pairs(extensions) do
    table.insert(list, name)
  end
  return list
end


abi.register(transfer, transferFrom, set_contract_owner)
abi.register_view(name, symbol, balanceOf, ownerOf, totalSupply, nextToken, tokenFromUser, arc2_extensions)
