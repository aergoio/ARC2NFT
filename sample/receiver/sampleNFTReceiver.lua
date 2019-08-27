function constructor(tokenContractAddress)
    assert(tokenContractAddress ~= nil)
    system.setItem("tokenCtr", tokenContractAddress)
  end
  
  -- ************************************************
  -- This function is token receive hook
  function onARC2Received(operator, from, tokenId, success, ...)
    if success ~= true then
      error("contract is fail")
    end
    -- print memo
    for k, v in pairs({...}) do system.print("Arg#"..k.."="..tostring(v)) end
  end
  -- ************************************************
  
  function withdraw(to, tokenId, ...)
    contract.call(system.getItem("tokenCtr"), "transfer", to, tokenId, ...)
  end

  function contractTransferFrom(to, tokenId, ...)
    contract.call(system.getItem("tokenCtr"), "transferFrom", system.getSender(), to, tokenId, ...)
  end
  
  function contractBurnFrom(tokenId)
    contract.call(system.getItem("tokenCtr"), "burnFrom", system.getSender(), tokenId)
  end
  
  abi.register(withdraw, contractTransferFrom, contractBurnFrom, onARC2Received)