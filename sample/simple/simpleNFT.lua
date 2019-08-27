import "aergoio/ARC2NFT"

function constructor()
    _init("simpleNFT", "SYMNFT")    
end

function mint(to, tokenId, ...)
    assert(system.getSender() == system.getCreator(), "only contract owner can mint")
    -- check existance
    _mint(to, tokenId, ...)
end

function burn(tokenId)
    _burn(system.getSender(), tokenId)
end

function burnFrom(from, tokenId)
    assert(isApprovedForAll(from, system.getSender()), "caller is not approved for holder")

    _burn(from, tokenId)
end

abi.register(mint, burn, burnFrom)