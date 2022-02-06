
function mint(to, tokenId, ...)
  assert(system.getSender() == system.getCreator(), "ARC2: only the contract owner can mint")
  _mint(to, tokenId, ...)
end

abi.register(mint)
