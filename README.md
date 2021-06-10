# Aergo Non Fungible Token Contract, ARC-2

This defines interface and behaviors for aergo non fungible token contract.

## Abstract

## Specification

### Token

Following is an interface contract declaring the required functions to meet the ARC-2 standard.
Issuers can add functions like name(), symbol(), mint() and burn() as needed.

(NOTE) The token id is a string of up to 128 lengths.

``` lua
-- Count of all NFTs assigned to an owner
-- @type    query
-- @param   owner  (address) a target address
-- @return  (ubig) the number of NFT tokens of owner
function balanceOf(owner) end

-- Find the owner of an NFT
-- @type    query
-- @param   tokenId (str128) the NFT id
-- @return (address) the address of the owner of the NFT
function ownerOf(tokenId) end

-- Transfer a token of 'from' to 'to'
-- @type    call
-- @param   from    (address) a sender's address
-- @param   to      (address) a receiver's address
-- @param   tokenId (str128) the NFT token to send
-- @param   ...     (Optional) addtional data, MUST be sent unaltered in call to 'onARC2Received' on 'to'
-- @event   transfer(from, to, value)
function safeTransferFrom(from, to, tokenId, ...) end

-- Change or reaffirm the approved address for an NFT
-- @type    call
-- @param   to          (address) the new approved NFT controller
-- @param   tokenId     (str128) the NFT token to approve
-- @event   approve(owner, to, tokenId)
function approve(to, tokenId) end

-- Get the approved address for a single NFT
-- @type    query
-- @param   tokenId  (str128) the NFT token to find the approved address for
-- @return  (address) the approved address for this NFT, or the zero address if there is none
function getApproved(tokenId) end

-- Allow operator to control all sender's token
-- @type    call
-- @param   operator  (address) a operator's address
-- @param   approved  (boolean) true if the operator is approved, false to revoke approval
-- @event   approvalForAll(owner, operator, approved)
function setApprovalForAll(operator, approved) end

-- Get allowance from owner to spender
-- @type    query
-- @param   owner       (address) owner's address
-- @param   operator    (address) allowed address
-- @return  (bool) true/false
function isApprovedForAll(owner, operator) end

```

Metadata extension

``` lua
function name() end

function symbol() end
```


### Hook

Contracts, that want to handle tokens, must implement the following functions to define how to handle the tokens they receive. If this function is not implemented, the token transfer will fail. Therefore, it is possible to prevent the token from being lost.

``` lua
-- The ARC2 smart contract calls this function on the recipient after a 'transfer'
-- @param   operator    (address) a address which called token 'transfer' function
-- @param   from        (address) a sender's address
-- @param   value       (ubig) an amount of token to send
-- @param   ...         addtional data, by-passed from 'transfer' arguments
-- @type    call
function onARC2Received(operator, from, tokenId, ...) end
```
