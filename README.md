# Aergo Non Fungible Token Contract, ARC-2

This defines interface and behaviors for aergo non fungible token contract.

## Abstract

## Specification

### Token

Following is an interface contract declaring the required functions to meet the ARC-2 standard.
Issuers can add functions like name(), symbol(), and burn() as needed.


``` lua
-- Count of all NFTs assigned to an owner
-- @type    query
-- @param   owner  (address) a target address
-- @return  (ubig) the number of NFT tokens of owner
function balanceOf(owner) end

-- Find the owner of an NFT
-- @type    query
-- @param   tokenId (ubig) the NFT id
-- @return (ubig) the address of the owner of the NFT
function ownerOf(tokenId) end

-- Transfer sender's token to target 'to'
-- @type    call
-- @param   to      (address) a target address
-- @param   tokenId (ubig) the NFT token to send
-- @param   ...     addtional data, MUST be sent unaltered in call to 'tokensReceived' on 'to'
-- @event   transfer(from, to, value)
function transfer(to, tokenId, ...) end

-- Get allowance from owner to spender
-- @type    query
-- @param   owner       (address) owner's address
-- @param   operator    (address) allowed address
-- @return  (bool) true/false
function isApprovedForAll(owner, operator) end

-- Allow operator to use all sender's token
-- @type    call
-- @param   operator  (address) a operator's address
-- @param   approved  (boolean) true/false
-- @event   approve(owner, operator, approved)
function setApprovalForAll(operator, approved) end

-- Transfer 'from's token to target 'to'.
-- Tx sender have to be approved to spend from 'from'
-- @type    call
-- @param   from    (address) a sender's address
-- @param   to      (address) a receiver's address
-- @param   tokenId   (ubig) an amount of token to send
-- @param   ...     addtional data, MUST be sent unaltered in call to 'tokensReceived' on 'to'
-- @event   transfer(from, to, value)
function transferFrom(from, to, tokenId, ...) end

```

Enumerable extension

``` lua
function name() end

function symbol() end

function tokenURI(tokenId) end
```

Enumerable extension

``` lua
-- Get a total number of NFT tokens tracked by this contract
-- @type    query
-- @return  (ubig) total supply of valid NFT tokens by this contract
function totalSupply() end

-- Enumerate valid NFTs
-- @type    query
-- @param   index   A counter less than 'totalSupply()'
-- @return  (ubig) The token id for the 'index'th NFT (sort order not specified)
function tokenByIndex(index) end

-- Enumerate NFTs assigned to an owner
-- @type    query
-- @param   owner   An address where we are interested
-- @param   index   A counter less than 'balanceOf(owner)'
-- @return  (ubig) The token id for the 'index'th NFT assigned to owner (sort order not specified)
function tokenOfOwnerByIndex(owner, index) end

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
