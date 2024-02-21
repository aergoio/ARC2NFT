# Aergo Non-Fungible Token Contract - ARC2

Although NFTs are mostly known to record image ownership, they can be used for many cases:

* Tickets (shows, parking, airplane, hotel reservation...)
* Access control
* Identity Verification (including birth certificates and KYC)
* Documents (including certificates and licenses)
* Academic and Professional Credentials
* Attendance/Participation Credentials
* Awards
* Medical Records
* Voting and DAOs
* Intellectual Property and Patents
* Engineering/Architectural design (including usage rights)
* Product Authenticity and Supply Chain (food, pharmaceuticals, fashion...)
* Real-estate property (including rent)
* Ownership tracking
* History tracking (eg. car maintainance services)
* Insurance
* Record shares of resources
* Gaming
* Sports


## Token Structure

When creating a token, the token issuer can store data in 2 places:

* Token Id
* Metadata

### Token Id

The **Token Id** is a string of up to 128 bytes. It must be unique for each token.

Whenever a new token is created the contract will check if another token with the same
id already exists.

The data stored in the token id is **immutable**.

### Metadata

The **Metadata** is the data stored attached to the token id, in the format of key-value pairs.

The token issuer can set the metadata either at mint time or later, using the `set_metadata`
function.

The metadata can be either **mutable**, **immutable** or **incremental**.

#### Immutable Metadata

The token creator can mark a specific metadata key as immutable using the
`make_metadata_immutable` function. This is done just once for each unique key.
After this property is set for a metadata key, it cannot be removed.

If the metadata is immutable, it means that once it is set on a token it can no longer be modified.

It gives the guarantee to the owner that the creator/issuer will not modify or
remove this specific metadata.

#### Incremental Metadata

The token creator can mark a specific metadata key as incremental using the
`make_metadata_incremental` function. This is done just once for each unique key.
After this property is set for a metadata key, it cannot be removed.

If the metadata is incremental, it means that once it is set on a token it can only be incremented.

It gives the guarantee to the owner that the creator/issuer can only increment this value.
Useful for expiration time, for example.

#### Mutable Metadata

Any metadata key that is not marked as immutable or incremental is mutable.

The token issuer can modify the metadata by either updating the value or removing the
whole key-value pair from the token.

This is done using the `set_metadata` and `remove_metadata` functions.


## Where to store token data?

Mutable data must be stored as metadata.

Immutable data can be in either places. Store it in the token id if the
data is used to uniquely identify the token. Otherwise it can be stored as metadata.

Example:

For tickets we can store the event name, location, date, and seat number in the
token id. By using the same format of storing this data we can check if the ticket
is already issued, retrieve the owner, etc.

The data in the token id can be arranged in a key-value format, like this:

```
event=Josh_Concert,date=1645379800,place=Clark_Stadium,section=green,seat=15D,team=away
```

Or as a comma separated list, like this:

```
Josh_Concert,1645379800,Clark_Stadium,green,D15,away
```

Or whatever format suits your needs, just remembering that it must be a string with
up to 128 bytes.

You can also store version info in the beginning, just in case you change the format
later.

It is also common to store just an incremental number as the token id, and additional
data either in the metadata or in external storage.


### External Data

Non-fungible token contracts are **not** meant to be used to store lots of data for
each token. Its main use it to store some key information on the token and, if
there is more data related to it, store them externally. Either in normal databases
or in storage-dedicated blockchains, like IPFS, Filecoin, Storj or Bittorrent.

For artwork, we recommend to store the image/video/music on a storage-dedicated
blockchain and then store the identifier in the token id.

For real-state, you can store the property identifier on the token and the remaining,
like documents, on a descentralized storage or private database.

Similar for Academic Credentials, Documents, Patents, Designs...


## Creating Tokens

The tokens can be created at contract creation time and also later, if the
contract includes the `mintable` extension.

### Initial Supply

The tokens created at the contract creation are named *Initial Supply*

They can be informed as a list of token ids:

```lua
local initial_supply = {
  "Josh_Concert,1645379800,Clark_Stadium,D01",
  "Josh_Concert,1645379800,Clark_Stadium,D02",
  "Josh_Concert,1645379800,Clark_Stadium,D03"
}
```

Or as a list of token ids and metadata:

```lua
local initial_supply = {
  { "Josh_Concert,1645379800,Clark_Stadium,D01", {key1 = value1, key2 = value2} },
  { "Josh_Concert,1645379800,Clark_Stadium,D02", {key1 = value1, key2 = value2} },
  { "Josh_Concert,1645379800,Clark_Stadium,D03", {key1 = value1, key2 = value2} },
}
```

### Minting Additional Tokens

To use this feature the contract must include the `mintable` extension.

The contract creator can mint new tokens using the `mint` function, informing
the token owner, the token id and metadata.

Example call from a contract:

```lua
contract.call(token, "mint", to, tokenId, {key = value, key2 = value2})
```

Example transaction:

```
"type": CALL,
"payload": {
  "function": "mint",
  "args": [to, tokenId, {"key": value, "key2": value2}]
}
```

It is also possible to allow other accounts to mint tokens, using the `addMinter`
function. For more info, check the [mintable extension](#mintable-extension).


### Max Supply

It is possible to set a limit on the number of tokens that a contract can
contain.

This is done at contract creation time, informing the maximum amount
in the options, as `max_supply`.

Here is an example with a max supply of 1000:

```lua
local token = contract.call(arc2_factory, "new_arc2_nft", name, symbol,
                            initial_supply, {mintable=true,max_supply=1000})
```


## Non-Transferable Tokens

When a token is non-transferable, it cannot be transferred to other users.

It is useful for identity related badges, like KYC, certificates, credentials, lisenses, awards...

There are 2 ways in which a token can be non-transferable:

* If the token contract has the `non_transferable` extension
* If the specific token has the `non_transferable` metadata

On the first case, all tokens on the contract are non-transferable.

On the second case, the contract can have both transferable and non-transferable tokens.

The `non_transferable` metadata can only be set at token creation/mint time, but it can
be removed later.


## Recallable Tokens

When a token is recallable, it can be transferred (seized) by the token creator.

There are 2 ways in which a token can be recallable:

* If the token contract has the `recallable` extension
* If the specific token has the `recallable` metadata

On the first case, all tokens on the contract are recallable.

On the second case, the contract can have both recallable and non-recallable tokens.

The `recallable` metadata can only be set at token creation/mint time, but it can
be removed later.


## Behavior Table

| Non-Transferable   | Recallable | Behavior
| :----------------: | :--------: | ---------------------------------------------
|                    |                    | Only the owner (and authorized accounts) can transfer
| :white_check_mark: |                    | No one can transfer it
|                    | :white_check_mark: | The owner, authorized, and creator/issuer can transfer
| :white_check_mark: | :white_check_mark: | Only the creator/issuer can transfer



## Specification

This defines the interface and behaviors for aergo non-fungible token contract.

### Core Module

The following is an interface contract declaring the required functions to meet the ARC2 standard.

``` lua
-- Get the token name
-- @type    query
-- @return  (string) name of this token
function name() end

-- Get the token symbol
-- @type    query
-- @return  (string) symbol of this token
function symbol() end

-- Count of all NFTs
-- @type    query
-- @return  (integer) the number of non-fungible tokens on this contract
function totalSupply() end

-- Count of all NFTs assigned to an owner
-- @type    query
-- @param   owner  (address) a target address
-- @return  (integer) the number of NFT tokens of owner
function balanceOf(owner) end

-- Find the owner of an NFT
-- @type    query
-- @param   tokenId (str128) the NFT id
-- @return (address) the address of the owner of the NFT
function ownerOf(tokenId) end

-- Transfer a token
-- @type    call
-- @param   to      (address) the receiver address
-- @param   tokenId (str128) the NFT token to send
-- @param   ...     (Optional) additional data, is sent unaltered in a call to 'nonFungibleReceived' on 'to'
-- @return  value returned from the 'nonFungibleReceived' callback, or nil
-- @event   transfer(from, to, tokenId)
function transfer(to, tokenId, ...) end

-- Returns a JSON string containing the list of ARC2 extensions
-- that were included on the contract.
-- @type    query
function arc2_extensions() end
```

These additional functions below are also present in the core module

The `enumerable` functions:

```lua
-- Retrieves the next token in the contract
-- @type    query
-- @param   prev_index (integer) the index of the previous returned token. use `0` in the first call
-- @param   max_items (integer) the maximum number of items to return
-- @return  (index, tokenId) the index of the next token and its token id, or `nil,nil` if no more tokens
function nextToken(prev_index, max_items)

-- Retrieves the token from the given user at the given position
-- @type    query
-- @param   user      (address) ..
-- @param   position  (integer) the position of the token in the incremental sequence
-- @param   max_items (integer) the maximum number of items to return
-- @return  tokenId   (str128) the token id, or `nil` if no more tokens on this account
function tokenFromUser(user, position, max_items)
```


### Metadata extension

``` lua
-- Store non-fungible token metadata
-- @type    call
-- @param   tokenId  (str128) the non-fungible token id
-- @param   metadata (table)  lua table containing key-value pairs
function set_metadata(tokenId, metadata)

-- Remove non-fungible token metadata
-- @type    call
-- @param   tokenId  (str128) the non-fungible token id
-- @param   list     (table)  lua table containing list of keys to remove
function remove_metadata(tokenId, list)

-- Retrieve non-fungible token metadata
-- @type    query
-- @param   tokenId  (str128) the non-fungible token id
-- @param   key      (string) the metadata key
-- @return  (string) if key is nil, return all metadata from token,
--                   otherwise return the value linked to the key
function get_metadata(tokenId, key)

-- Mark a specific metadata key as immutable. This means that once this metadata
-- is set on a token, it can no longer be modified. And once this property is set
-- on a metadata, it cannot be removed. It gives the guarantee to the owner that
-- the creator/issuer will not modify or remove this specific metadata.
-- @type    call
-- @param   key  (string) the metadata key
function make_metadata_immutable(key)

-- Mark a specific metadata key as incremental. This means that once this metadata
-- is set on a token, it can only be incremented. Useful for expiration time.
-- Once this property is set on a metadata, it cannot be removed. It gives the
-- guarantee to the owner that the creator/issuer can only increment this value.
-- @type    call
-- @param   key  (string) the metadata key
function make_metadata_incremental(key)

-- Retrieve the list of immutable and incremental metadata
-- @type    query
-- @return  (string) a JSON object with each metadata as key and the property
--                   as value. Example: {"expiration": "incremental", "index": "immutable"}
function get_metadata_info()
```

### Mintable extension

``` lua
-- Indicate if an account is a minter
-- @type    query
-- @param   account  (address)
-- @return  (bool) true/false
function isMinter(account)

-- Add an account to the minters group
-- @type    call
-- @param   account  (address)
-- @event   addMinter(account)
function addMinter(account)

-- Remove an account from the minters group
-- @type    call
-- @param   account  (address)
-- @event   removeMinter(account)
function removeMinter(account)

-- Renounce the minter role
-- @type    call
-- @event   removeMinter(caller)
function renounceMinter()

-- Mint a new non-fungible token
-- @type    call
-- @param   to       (address) recipient's address
-- @param   tokenId  (str128) the non-fungible token id
-- @param   metadata (table) lua table containing key-value pairs
-- @param   ...      additional data, is sent unaltered in a call to 'nonFungibleReceived' on 'to'
-- @return  value returned from the 'nonFungibleReceived' callback, or nil
-- @event   mint(to, tokenId)
function mint(to, tokenId, metadata, ...)

-- Retrieve the Max Supply
-- @type    query
-- @return  amount   (integer) the maximum amount of tokens that can be active on the contract
function maxSupply()
```

### Burnable extension

``` lua
-- Burn a non-fungible token
-- @type    call
-- @param   tokenId  (str128) the identifier of the token to be burned
-- @event   burn(owner, tokenId)
function burn(tokenId) end
```

### Approval extension

```lua
-- Approve an account to operate on the given non-fungible token.
-- Use `nil` on the operator to remove the approval
-- @type    call
-- @param   operator    (address) the new approved NFT controller
-- @param   tokenId     (str128) the NFT token to be controlled
-- @event   approve(owner, operator, tokenId)
function approve(operator, tokenId) end

-- Get the approved operator address for a given non-fungible token
-- @type    query
-- @param   tokenId  (str128) the NFT token to find the approved operator
-- @return  (address) the approved operator address for this NFT, or nil if there is none
function getApproved(tokenId) end

-- Allow an operator to control all the sender's tokens
-- @type    call
-- @param   operator  (address) the operator address
-- @param   approved  (boolean) true if the operator is approved, false to revoke approval
-- @event   approvalForAll(owner, operator, approved)
function setApprovalForAll(operator, approved) end

-- Check if the given operator is approved to control the owner's tokens
-- @type    query
-- @param   owner       (address) owner address
-- @param   operator    (address) operator address
-- @return  (bool) true/false
function isApprovedForAll(owner, operator) end

-- Transfer a non-fungible token of 'from' to 'to'
-- @type    call
-- @param   from    (address) the owner address
-- @param   to      (address) the receiver address
-- @param   tokenId (str128) the non-fungible token to send
-- @param   ...     (Optional) additional data, is sent unaltered in a call to 'nonFungibleReceived' on 'to'
-- @return  value returned from the 'nonFungibleReceived' callback, or nil
-- @event   transfer(from, to, tokenId, operator)
function transferFrom(from, to, tokenId, ...) end
```

### Pausable extension

``` lua
-- Indicate whether an account has the pauser role
-- @type    query
-- @param   account  (address)
-- @return  (bool) true/false
function isPauser(account)

-- Grant the pauser role to an account
-- @type    call
-- @param   account  (address)
-- @event   addPauser(account)
function addPauser(account)

-- Remove the pauser role form an account
-- @type    call
-- @param   account  (address)
-- @event   removePauser(account)
function removePauser(account)

-- Renounce the granted pauser role
-- @type    call
-- @event   removePauser(account)
function renouncePauser()

-- Indicate if the contract is paused
-- @type    query
-- @return  (bool) true/false
function paused()

-- Put the contract in a paused state
-- @type    call
-- @event   pause(caller)
function pause()

-- Return the contract to the normal state
-- @type    call
-- @event   unpause(caller)
function unpause()
```

### Blacklist extension

``` lua
-- Add accounts to the blacklist
-- @type    call
-- @param   account_list (list of address)
-- @event   addToBlacklist(account_list)
function addToBlacklist(account_list)

-- Remove accounts from the blacklist
-- @type    call
-- @param   account_list  (list of address)
-- @event   removeFromBlacklist(account_list)
function removeFromBlacklist(account_list)

-- Indicate if an account is on the blacklist
-- @type    query
-- @param   account   (address)
function isOnBlacklist(account)
```

### NonTransferable extension

There are no exported functions

It is used to make non-transferable tokens (badges)


### Recallable extension

There are no exported functions

It is used to make recallable tokens


### Searchable extension

It is used to search for tokens using REGEX pattern.

```lua
-- Find the next token that matches the given query
-- @type    query
-- @param   query      (table) lua table containing parameters used by the search
-- @param   prev_index (integer) the index of the previous returned token. use `0` in the first call
-- @return  (index, tokenId) the index of the next found token and its token id
function findToken(query, prev_index)
```

Check instructions bellow for usage and examples


### Hook

This function is required to receive ARC2 non-fungible tokens

Contracts that want to receive non-fungible tokens must implement the following function in order to receive them.
In most cases it also means that your contract must have methods to transfer these tokens.

If your contract is not intended to handle non-fungible tokens, then do not add this function. In this case any
attempt to transfer a NFT to your contract will fail (as expected).

This function can also be used to define how to handle the tokens they receive.

``` lua
-- The ARC2 smart contract calls this function on the recipient contract after a 'transfer' or 'mint'
-- @type    call
-- @param   operator    (address) the address that called the token 'transfer' or 'mint'
-- @param   from        (address) the sender's address (nil if being minted)
-- @param   tokenId     (str128)  the non-fungible token id
-- @param   ...         additional data, by-passed from 'transfer' or 'mint' arguments
function nonFungibleReceived(operator, from, tokenId, ...)
  -- do nothing
end
```

> :warning: **ATTENTION:** anyone can call this function! :warning:
> 
> Do NOT assume a token was received just because this function was called!

If a token was really sent, we can get the token contract address with:

```lua
local token_contract = system.getSender()
```

But on most cases the function can be empty.


### List and Find Tokens

To list tokens we use the `nextToken` function.

```lua
function nextToken(prev_index)
```

To list tokens from an user we use the `tokenFromUser` function.

```lua
function tokenFromUser(user, position)
```

To find tokens with specific properties we use the `findToken` function.

```lua
function findToken(query, prev_index)
```

It retrieves the first token found that matches the query.
The query is a lua table that can contain these fields:

* **owner**    - the owner of the token (address)
* **contains** - check if the tokenId contains this string
* **pattern**  - check if the tokenId matches this Lua regex pattern
* **metadata** - check if the token metadata matches this sub-query

The sub-query is a lua table containing the metadata key, the operator
to use and the value, in this format:

```lua
metadata = { key = {op = ">", value = 10} }
```

The operators are: `= > >= < <= between match` and negated: `!= !between !match`

The `prev_index` must be `0` in the first call.
For the next calls, just inform the returned index from the previous call.

The returned value is `index, tokenId`

If no token is found with the given query, it returns `nil, nil`


#### Examples

List all tokens on the contract:

```lua
  local index = 0
  local tokenId
  do
    index, tokenId = nextToken(index)
    if tokenId then
      ...
    end
  while index > 0
```

List the tokens from an user:

```lua
  local position = 1
  while true do
    local tokenId = tokenFromUser(owner, position)
    if tokenId == nil then break end
    ...
    position = position + 1
  end
```

List the tokens that contain a specific text:

```lua
  local index = 0
  local tokenId
  do
    index, tokenId = findToken({contains=text}, index)
    if tokenId then
      ...
    end
  while index > 0
```

List the tokens that match a specific regex pattern:

```lua
  local index = 0
  local tokenId
  do
    index, tokenId = findToken({pattern=text}, index)
    if tokenId then
      ...
    end
  while index > 0
```

List the tokens from an user that match a specific regex pattern:

```lua
  local index = 0
  local tokenId
  do
    index, tokenId = findToken({owner=address,pattern=text}, index)
    if tokenId then
      ...
    end
  while index > 0
```

List the tokens from an user that have not expired yet:

```lua
  local query = {owner=address, metadata={expiration = {op=">", value=1645379800}}}
  local index = 0
  local tokenId
  do
    index, tokenId = findToken(query, index)
    if tokenId then
      ...
    end
  while index > 0
```
