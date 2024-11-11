# OllieCoin

## Part 1
clone repo with:
```
git clone https://github.com/lukmaan-k/olliecoin.git
```

run unit test with:
```
forge test -vvv
```
Include the -vvv flag to see console.log outputs from unit test

## Part 2

### Design Decisions
- Both OllieCoin and RewardCoin are OFTs
- OllieCoin needs to track the total balance for a user across all chains
  - The 'main' OllieCoin tracks the balances (referred to as the Server OllieCoin)
  - Server OllieCoin is notified of any token transfers happeneing on remote chains (Client OllieCoins)
  - The above means the checkpointing logic only needs to exist on Server OllieCoin, with Client OllieCoin only containing additional logic to notify the Server OllieCoin of token transfers and claims
- RewardCoin is a simple OFT, and unlike OllieCoin, is the same on all chains

### Distribution
No different to the single-chain model. Ensure that the amount of RewardCoin corresponds to the totalSupply of OllieCoin for _all_ chains

### Client chain OllieCoin transfers
Same idea as single-chain model, except the checkpointing hook which is normally called happens on Server OllieCoin

### Client chain claim()
Order of operation:
1. User presses claim on client chain
2. Client OllieCoin calls Server OllieCoin's claim() function through LayerZero
3. Server OllieCoin is aware of the total balance of the user across all chains, so calculates the reward amount as in single-chain model
4. Server OllieCoin notifies RewardCoin to do a cross-chain transfer to the user
5. RewardCoin does a simple OFTSend using layerzero, which involves burning on source side, and minting on destination side

![Alt text](docs/crossChainDistribution.svg)
