# ARC2 NFT Factory

It is a contract that is used to create ARC2 non-fungible token contracts

We create a new token by calling the `new_arc2_nft` function and informing
the arguments:

* Name
* Symbol
* Initial Supply
* Options (optional)
* Owner   (optional)

The options is a table informing which extensions to add to the token:

* burnable
* mintable
* pausable
* blacklist
* approval

The `owner` is the address that will be registered as the owner of the
token contract. By default it is the entity calling the factory, but
we can specify any address.


## Creating from another contract

The call uses this format:

```lua
contract.call(arc2_factory, "new_arc2_nft", name, symbol, initial_supply, options)
```

The function returns the contract address.

Here is an example with an initial supply of tokens:

```lua
local initial_supply = {
  "lkjhaosdiufyaodfuia01",
  "lkjhaosdiufyaodfuia02",
  "lkjhaosdiufyaodfuia03"
}
local token = contract.call(arc2_factory, "new_arc2_nft", name, symbol,
                            initial_supply, {mintable=true,approval=true})
```

And how to inform a total supply (for mintable tokens):

```lua
local token = contract.call(arc2_factory, "new_arc2_nft", name, symbol,
                            nil, {mintable=true,max_supply=1000})
```

If you do not specify `mintable` in the options, then the contract will only
contain the tokens informed as the initial supply (fixed supply).

The factory can also be called from herajs, herapy, libaergo...


## Token Factory Address

<table>
  <tr><td>testnet</td><td>-</td></tr>
  <tr><td>alphanet</td><td>-</td></tr>
</table>


## Updating the Factory

If some of the contract files were modified, a new factory can be created.

Run:

```
./build.sh
```

Then deploy the generated `output.lua` to the network and update services
that use it.
