# flutter_basic_pay
This is a demo app showing how to uses flutter to implement a stellar payment app.

## Installation

Clone this repository, get the dependencies and start the app in `main.dart`.

## Demo

The app showcases how to use the [flutter wallet sdk](https://github.com/Soneso/stellar_wallet_flutter_sdk/)
to create a stellar payment app. It is a non-custodial app, that secures the users keypair encrypted in the
secure storage of the device. Only the user who knows the pin can decrypt it to sign transactions.

The app currently has following features:

- signup
- sign in
- encrypting of secret seed and secure storage of data
- create account
- fund account on testnet
- fetch account data from the stellar network
- add and remove asset support
- send payments
- fetch recent payments
- find strict send and strict receive payment paths
- send path payments
- add and use contacts