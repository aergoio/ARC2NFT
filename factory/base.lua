arc2_core = [[
%core%
]]

arc2_burnable = [[
%burnable%
]]

arc2_mintable = [[
%mintable%
]]

arc2_pausable = [[
%pausable%
]]

arc2_blacklist = [[
%blacklist%
]]

arc2_approval = [[
%approval%
]]

arc2_constructor = [[
state.var {
  _creator = state.value()
}

function constructor(name, symbol, initial_supply, max_supply, owner)
  _init(name, symbol)
  _creator:set(owner)
  if initial_supply then
    for _,tokenId in ipairs(initial_supply) do
      _mint(owner, tokenId)
    end
  end
  if max_supply then
    _setMaxSupply(max_supply)
  end
end
]]

function new_arc2_nft(name, symbol, initial_supply, options, owner)

  if options == nil or options == '' then
    options = {}
  end

  if owner == nil or owner == '' then
    owner = system.getSender()
  end

  local contract_code = arc2_core .. arc2_constructor

  if options["burnable"] then
    contract_code = contract_code .. arc2_burnable
  end
  if options["mintable"] then
    contract_code = contract_code .. arc2_mintable
  end
  if options["pausable"] then
    contract_code = contract_code .. arc2_pausable
  end
  if options["blacklist"] then
    contract_code = contract_code .. arc2_blacklist
  end
  if options["approval"] then
    contract_code = contract_code .. arc2_approval
  end

  local max_supply = options["max_supply"]
  if max_supply then
    assert(options["mintable"], "max_supply is only available with the mintable extension")
    max_supply = tonumber(max_supply)
    if initial_supply then
      assert(max_supply >= #initial_supply, "the max supply must be bigger than the initial supply count")
    end
  end

  local address = contract.deploy(contract_code, name, symbol, initial_supply, max_supply, owner)

  contract.event("new_arc2_token", address)

  return address
end

abi.register(new_token)
