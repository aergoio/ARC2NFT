------------------------------------------------------------------------------
-- Aergo Standard NFT Interface (Proposal) - 20210425
------------------------------------------------------------------------------

extensions["metadata"] = true

reserved_metadata = { "index", "owner", "approved" }

local function is_reserved_metadata(name)
  for _,reserved in ipairs(reserved_metadata) do
    if name == reserved then
      return true
    end
  end
  return false
end

--- Exported Functions ---

-- Store non-fungible token metadata
-- @type    call
-- @param   tokenId  (str128) the non-fungible token id
-- @param   metadata (table)  lua table containing key/value pairs
function set_metadata(tokenId, metadata)
  _typecheck(tokenId, 'str128')

  assert(system.getSender() == system.getCreator(), "ARC2: permission denied")
  assert(not _paused:get(), "ARC2: paused contract")

  local token = _tokens[tokenId]
  assert(token ~= nil, "ARC2: nonexisting token")
  for key,value in pairs(metadata) do
    assert(not is_reserved_metadata(key), "ARC2: reserved metadata")
    token[key] = value
  end
  _tokens[tokenId] = token
end

-- Remove non-fungible token metadata
-- @type    call
-- @param   tokenId  (str128) the non-fungible token id
-- @param   list     (table)  lua table containing list of keys to remove
function remove_metadata(tokenId, list)
  _typecheck(tokenId, 'str128')

  assert(system.getSender() == system.getCreator(), "ARC2: permission denied")
  assert(not _paused:get(), "ARC2: paused contract")

  local token = _tokens[tokenId]
  assert(token ~= nil, "ARC2: nonexisting token")
  for _,key in pairs(list) do
    assert(not is_reserved_metadata(key), "ARC2: reserved metadata")
    token[key] = nil
  end
  _tokens[tokenId] = token
end

-- Retrieve non-fungible token metadata
-- @type    query
-- @param   tokenId  (str128) the non-fungible token id
-- @param   key      (string) if nil, return all metadata, otherwise just the requested
function get_metadata(tokenId, key)
  _typecheck(tokenId, 'str128')

  assert(system.getSender() == system.getCreator(), "ARC2: permission denied")
  assert(not _paused:get(), "ARC2: paused contract")

  local token = _tokens[tokenId]
  assert(token ~= nil, "ARC2: nonexisting token")

--[[
  token["index"] = nil
  token["owner"] = nil
  token["approved"] = nil
]]

  if key == nil then
    return token  -- or JSON
  end

  return token[key]
end

abi.register_view(get_metadata)
abi.register(set_metadata, remove_metadata)
