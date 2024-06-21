# Overview
> **Note:** This tutorial walks through how to build a payment application with Flutter. It mainly uses the [`flutter_wallet_sdk`](https://developers.stellar.org/docs/building-apps/wallet/overview).
In some cases it also uses the core [`stellar_flutter_sdk`](https://github.com/Soneso/stellar_flutter_sdk).

In this tutorial, we'll walk through the steps needed to build a basic payment application on Stellar's Testnet with Flutter.
After this tutorial, you should have a good understanding of the fundamental Stellar concepts.

For this tutorial, we'll walk through the steps as we build a sample application we've called [Flutter Basic Pay](https://github.com/Soneso/flutter_basic_pay), which will be used to showcase various features.

> **Caution:**
Although Flutter BasicPay is a full-fledged application on Stellar's Testnet, it has been built solely to showcase Stellar functionality for the educational purposes of this tutorial, not to be copied, pasted, and used on Mainnet.

## Installation

Clone the [Flutter Basic Pay](https://github.com/Soneso/flutter_basic_pay) repository, get the dependencies and start the app in `main.dart`.

### Stellar dependencies

The stellar related dependencies are defined in [`pubspec.yaml`](https://github.com/Soneso/flutter_basic_pay/blob/main/pubspec.yaml).
The app uses the `stellar_wallet_flutter_sdk` and the `stellar_flutter_sdk` packages.


## Chapters

- [Secure data storage](secure_data_storage.md)
- [Authentication](authentication.md)
- [Sign up and login](signup_and_sign_in.md)
- [Dashboard State](dashboard_state.md)
- [Dashboard Data](dashboard_data.md)
- [Account creation](account_creation.md)
- [Manage trust](manage_trust.md)
- [Payment](payment.md)
- [Path payment](path_payment.md).

## Next

Continue with [Secure data storage](secure_data_storage.md).