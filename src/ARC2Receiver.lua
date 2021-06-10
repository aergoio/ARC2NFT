-- ARC2 token receiver interface
-- Interface for contract that wants to support safeTransfers from ARC2
-- @param   operator    (address) a address which called token 'transfer' function
-- @param   from        (address) a sender's address
-- @param   value       (ubig) an amount of token to send
-- @param   ...         addtional data, by-passed from 'transfer' arguments
-- @type    call
function onARC2Received(operator, from, tokenId, ... )
    -- TODO IMPLEMENT THIS
end
