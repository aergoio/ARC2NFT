------------------------------------------------------------------------------
-- Aergo Standard NFT Interface (Proposal) - 20210425
------------------------------------------------------------------------------

extensions["metadata"] = true

state.var {
  _immutable_metadata = state.value(),
  _incremental_metadata = state.value()
}

reserved_metadata = { "index", "owner", "approved" }

local function is_reserved_metadata(name)
  for _,reserved in ipairs(reserved_metadata) do
    if name == reserved then
      return true
    end
  end
  return false
end

local function check_metadata_update(name, prev_value, new_value)

  assert(not is_reserved_metadata(name), "ARC2: reserved metadata")

  local immutable = _immutable_metadata:get() or {}
  local incremental = _incremental_metadata:get() or {}

  for _,value in ipairs(immutable) do
    if value == name then
      assert(false, "ARC2: immutable metadata")
    end
  end
  for _,value in ipairs(incremental) do
    if value == name then
      if prev_value == nil then return end
      assert(new_value ~= nil and type(new_value) == type(prev_value) and
             new_value >= prev_value, "ARC2: incremental metadata")
      break
    end
  end

end

--- Exported Functions ---------------------------------------------------------

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
    check_metadata_update(key, token[key], value)
    assert(key ~= "non_transferable" and key ~= "recallable", "ARC2: permission denied")
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
  for _,key in ipairs(list) do
    check_metadata_update(key, token[key], nil)
    token[key] = nil
  end
  _tokens[tokenId] = token
end

-- Retrieve non-fungible token metadata
-- @type    query
-- @param   tokenId  (str128) the non-fungible token id
-- @param   key      (string) the metadata key
-- @return  (string) if key is nil, return all metadata from token,
--                   otherwise return the value linked to the key
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

-- Mark a specific metadata key as immutable. This means that once this metadata
-- is set on a token, it can no longer be modified. And once this property is set
-- on a metadata, it cannot be removed. It gives the guarantee to the owner that
-- the creator/issuer will not modify or remove this specific metadata.
-- @type    call
-- @param   key  (string) the metadata key
function make_metadata_immutable(key)
  _typecheck(key, 'string')
  assert(#key > 0, "ARC2: invalid key")
  assert(not is_reserved_metadata(key), "ARC2: reserved metadata")
  assert(system.getSender() == system.getCreator(), "ARC2: permission denied")
  assert(not _paused:get(), "ARC2: paused contract")

  local immutable = _immutable_metadata:get() or {}

  for _,value in ipairs(immutable) do
    if value == key then return end
  end

  table.insert(immutable, key)
  _immutable_metadata:set(immutable)
end

-- Mark a specific metadata key as incremental. This means that once this metadata
-- is set on a token, it can only be incremented. Useful for expiration time.
-- Once this property is set on a metadata, it cannot be removed. It gives the
-- guarantee to the owner that the creator/issuer can only increment this value.
-- @type    call
-- @param   key  (string) the metadata key
function make_metadata_incremental(key)
  _typecheck(key, 'string')
  assert(#key > 0, "ARC2: invalid key")
  assert(not is_reserved_metadata(key), "ARC2: reserved metadata")
  assert(system.getSender() == system.getCreator(), "ARC2: permission denied")
  assert(not _paused:get(), "ARC2: paused contract")

  local incremental = _incremental_metadata:get() or {}

  for _,value in ipairs(incremental) do
    if value == key then return end
  end

  table.insert(incremental, key)
  _incremental_metadata:set(incremental)
end

-- Retrieve the list of immutable and incremental metadata
-- @type    query
-- @return  (string) a JSON object with each metadata as key and the property
--                   as value. Example:
--[[
{
"expiration": "incremental",
"index": "immutable"
}
]]
function get_metadata_info()
  local immutable = _immutable_metadata:get() or {}
  local incremental = _incremental_metadata:get() or {}

  local list = {}

  list["index"] = "immutable"

  for _,value in ipairs(immutable) do
    list[value] = "immutable"
  end
  for _,value in ipairs(incremental) do
    list[value] = "incremental"
  end

  return json.encode(list)
end


abi.register_view(get_metadata, get_metadata_info)
abi.register(set_metadata, remove_metadata, make_metadata_immutable, make_metadata_incremental)
