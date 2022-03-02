-- ARC2 token receiver interface: for contracts that want to support ARC2 tokens
-- The ARC2 smart contract calls this function on the recipient contract after a 'transfer' or 'mint'
-- @param   operator    (address) the address that called the token 'transfer' or 'mint'
-- @param   from        (address) the sender's address (nil if being minted)
-- @param   tokenId     (str128)  the non-fungible token id
-- @param   ...         additional data, by-passed from 'transfer' or 'mint' arguments

function onARC2Received(operator, from, tokenId, ...)
    -- TODO: IMPLEMENT THIS ON YOUR CONTRACT
end
