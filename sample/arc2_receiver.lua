
state.var {
    _arc2ContractId = state.value()
}

-- ARC2 token receiver interface
function onARC2Received(operator, from, tokenId, ... )
    contract.event("GotARC2", operator, from, tokenId, ... )
end

function transferARC2(contractId, to, tokenId, ...)
    contract.call(contractId, "safeTransferFrom", system.getContractID(), to, tokenId, ...)
end

abi.register(transferARC2, onARC2Received)