# Banano

The current Gem trying to make as easy as possible working with [Banano currency](https://banano.cc/).
More information about the Banano currency networking can be found on the [Banano Currency Wiki pages](https://github.com/BananoCoin/banano/wiki/Network-Specifications).
The current library is still work in progress, but the basic functionallity is already implemented:

- Good part of the RPC protocol for working with Banano nodes
- Wallet, Account operations - send and receive payments etc.
- Conversion between units - RAW to Banano and Banano to RAW

Some parts of the library are heavily influenced by the great [nanook Ruby library](https://github.com/lukes/nanook) for working with the similar [NANO currency](https://nano.org/en/).

Everybody is welcome to contrubute to the project. Have fun and use Ruby and Banano.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'banano'
```

And then execute:

```sh
bundle install
```

Or install it yourself as:

```sh
gem install banano
```

## Usage

The code is divided on following the parts:

- `Banano::Unit` - conversion between [RAW and Banano units](https://nanoo.tools/banano-units)
- `Banano::Protocol` - including all other parts. Can be used also for some syntax sugar (to avoid sending node parameter to constructors)
- `Banano::Client` - very thin wrapper around [Faraday HTTP Client](https://github.com/lostisland/faraday) for easy JSON-based communications
- `Banano::Node` - Banano Node abstraction - mostly encapsulate JSON communications
- `Banano::Wallet` - wallets holding for Banano accounts on the current node
- `Banano::Account` - uniq 'ban_...' addresses used for currency tokens exchange
- `Banano::WalletAccount` - link between `Account` and `Wallet` - check if account exists in the wallet etc.
- `Banano::Key` - account key management

### Banano::Protocol

Usually everything starts here. By default the library will work with [locally running Banano node](https://github.com/BananoCoin/banano/wiki/Running-a-Docker-Bananode).
If it is impossible to be done, you can use the [Public bananode RPC API](https://nanoo.tools/bananode-api). Example below is for that case:

```rb
BETA_URL = 'https://api-beta.banano.cc'
@banano = Banano::Protocol.new(uri: BETA_URL)
# From here it is easy to create other object, without sending URI to them
wallet = @banano.wallet('WALLET15263636...')
account = @banano.account('ban_1...')
```

### Banano::Client

Not used directly, better use `Banano::Node` instead

```rb
client = Banano::Client.new(uri: BETA_URL)
client.rpc_call(action: :version)
```

### Banano::Node

Most of the information about the running node is encapsulated here. The other parts using  mostly the `Banano::Node.rpc()` method, not the low level client one:

```rb
Banano::Node.account_count # number of node accounts
Banano::Node.block_count   # check here if there are still non-syncronized blocks
Banano::Node.peers         # other nodes connected to that one
# accounts with voting power
Banano::Node.representatives
Banano::Node.representatives_online
# Is your node synced already
Banano::Node.synchronizing_blocks
Banano::Node.sync_progress
```

### Banano::Wallet

Wallets are like a bags of accounts. Accounts can be only local, created on the current node. They will not be visible for other nodes.

```rb
wallet = Banano::Wallet.create   # create new wallet
wallet.destroy                   # remove the wallet
wallet.export                    # export wallet to JSON
wallet.accounts                  # current wellet accounts
wallet.contains?('ban_1...')     # check if the account exists in the current wallet
# Accounts with voting power
wallet.default_representative
wallet.change_default_representative('ban_1...')
wallet.change_password('SomePassword')   # protect your wallet
wallet.lock                              # no more payments
wallet.locked?
wallet.unlock('SomePassword')            # resume receiving payments
wallet.balance                           # check how many banano the whole wallet have, RAW units
wallet.balance(raw: false)               # wallet balance in Banano units
wallet.balance(account_break_down: true) # banano per acount, RAW units
# Payments
wallet.pay(from: 'ban_1...', to: 'ban_3...', amount: '1.23', raw: false, id: 'x123')
wallet.pending(limit: 10, detailed: true)  # some payments waiting wallet unlock
wallet.receive(into: 'ban_1')            # receive the pending banano into some wallet account
wallet.restore(seed: 'XVVREGNN...')      # restore some wallet on the current node
```

### Banano::Account

Account are holding units with unique address, where the banano tokens are accumulated. They can be local for the current node and not accessable for other nodes.

```rb
account = Banano::Account(node: @banano.node, address: 'ban1_...')  # create new account on that node
account.exists?   # check if account exists
# some account attributes
account.last_modified_at
account.public_key
account.representative
account.balance             # in RAW units
account.balance(raw: false)  # in banano units
# Payments
account.pending(limit: 100, detailed: true)  # detailed information about the pending payments
account.history(limit: 10)  # the latest payments - send and receive
```

### Banano::WalletAccount

Because accounts and wallets so closly connected, some linkage object is very helpful.

```rb
wallet = @banano.wallet('XBHHNN...')
# create wallet <-> accounts connection
wallet_acc = Banano::WalletAccount(node: @banano.node, wallet: wallet.id)
wallet_acc.create     # create account in the wallet
wallet_acc.create(3)  # create additional 3 accounts inside the same wallet
# Working with specific account
account = @banano.account('ban_1')
wallet_other_acc = Banano::WalletAccount(node: pbanano.node, wallet: wallet.id, account: account.id)
wallet_other_acc.pay(to: 'ban_1...', amount: 10, raw: false, id: 'x1234')  # send some banano
wallet_other_acc.receive   # receive some banano

```

### Banano::Key

Most of the information is identicat with the [NANO currency docs](https://docs.nano.org/integration-guides/key-management/).

```rb
key_builder = @banano.key    # create new key (still unpopulated, cannot be used)
key_builder.generate         # generate private, public key and account address
{:private=>"43E6B...",
 :public=>"7EBC0C...",
 :account=>"ban_1zow3..."}
SEED = 'ABF56EBB...'         # Random seed
key_builder.generate(seed: SEED, index: 0)    # will always generate SAME pair of keys and address
key_builder.generate(seed: SEED, index: 1)
new_builder = @banano.key(saved_private_key)  # generate keys from saved private key
new_builder.expand                            # return private, public key and account address
```

### Banano::Unit

Using [Ruby bigdecimal library](https://apidock.com/ruby/BigDecimal) for all operations:

```rb
Banano::Unit.ban_to_raw(1)    # -> BigDecimal('100000000000000000000000000000')
Banano::Unit.raw_to_ban('1')  # -> BigDecimal('0.00000000000000000000000000001')
```

The library also is checking some currency related limits, for example total supply limit: `3402823669.20938463463374607431768211455` banano max

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

Clone the gem source code and start experimenting:

```sh
git clone https://github.com/zh/rbanano
```

`rspec` is used for testing. To run all tests execute:

```sh
bundle exec rspec spec
```

Still a lot of tests needed. For now `Banano::Unit` and `Banano:Util` are ready. The other parts tests will be added soon.

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/zh/rbanano](https://github.com/zh/rbanano).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
