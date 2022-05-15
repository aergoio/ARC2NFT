arc2_core = [[
%core%
]]

arc2_burnable = [[
%burnable%
]]

arc2_mintable = [[
%mintable%
]]

arc2_metadata = [[
%metadata%
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

arc2_searchable = [[
%searchable%
]]

arc2_non_transferable = [[
%non_transferable%
]]

arc2_recallable = [[
%recallable%
]]

arc2_constructor = [[
function constructor(name, symbol, initial_supply, max_supply, owner)
  _init(name, symbol, owner)
  if initial_supply then
    for _,token in ipairs(initial_supply) do
      _mint(owner, token[1], token[2])
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
  if options["metadata"] then
    contract_code = contract_code .. arc2_metadata
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
  if options["searchable"] then
    contract_code = contract_code .. arc2_searchable
  end
  if options["non_transferable"] then
    contract_code = contract_code .. arc2_non_transferable
  end
  if options["recallable"] then
    contract_code = contract_code .. arc2_recallable
  end

  if initial_supply then
    for index,value in ipairs(initial_supply) do
      if type(value) == "string" then
        initial_supply[index] = {value}
      end
    end
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

abi.register(new_arc2_nft)
