state.var {
  accepted_tokens = state.map()
}

-- This function is called when an ARC2 token is sent to this contract
-- But it is also called by any account, so do not trust it without making checks first
function nonFungibleReceived(operator, from, tokenId, ...)
  local token_contract = system.getSender()
  assert(accepted_tokens[token_contract] == true, "token not supported")

  contract.event("GotARC2", operator, from, tokenId, ...)
end

function add_accepted_token(address)
  assert(system.getSender() == system.getCreator(), "permission denied")
  accepted_tokens[address] = true
end

function transferARC2(contractId, to, tokenId, ...)
  assert(system.getSender() == system.getCreator(), "permission denied")
  contract.call(contractId, "transfer", to, tokenId, ...)
end

abi.register(nonFungibleReceived, add_accepted_token, transferARC2)
