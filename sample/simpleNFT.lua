import "aergoio/ARC2NFT"

function constructor()
    _init("simpleNFT", "SYMNFT")    
end

function mint(tokenId)
    -- check existance
    _mint(system.getCreator(), tokenId)
end

function burn(tokenId)
    _burn(system.getSender(), tokenId)
end

function burnFrom(from, tokenId)
    assert(isApprovedForAll(from, system.getSender()), "caller is not approved for holder")

    _burn(from, tokenId)
end

abi.register(mint, burn, burnFrom)