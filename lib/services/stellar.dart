import 'package:flutter_basic_pay/widgets/common/util.dart';
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart'
    as wallet_sdk;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart' as core_sdk;

class StellarService {
  /// [wallet_sdk.Wallet] used to communicate with the Stellar Test Network.
  static final wallet_sdk.Wallet _wallet = wallet_sdk.Wallet.testNet;

  /// Funds the account given by [address] on the Stellar Test Network by using Friendbot.
  static Future<bool> fundTestNetAccount(String address) async {
    // fund account
    return await _wallet.stellar().account().fundTestNetAccount(address);
  }

  /// Loads the assets for a given account specified by [address] from the
  /// Stellar Network by using the wallet sdk.
  static Future<List<AssetInfo>> loadAssetsForAddress(String address) async {
    var loadedAssets = List<AssetInfo>.empty(growable: true);
    try {
      var stellarAccountInfo =
          await _wallet.stellar().account().getInfo(address);
      for (var balance in stellarAccountInfo.balances) {
        loadedAssets.add(AssetInfo(
          asset: wallet_sdk.StellarAssetId.fromAsset(balance.asset),
          balance: balance.balance,
        ));
      }
    } on wallet_sdk.ValidationException {
      // account does not exist
      loadedAssets = List<AssetInfo>.empty(growable: true);
    }
    return loadedAssets;
  }

  /// Check if an account for the given [address] exists on the Stellar Network.
  static Future<bool> accountExists(String address) async {
    return await _wallet.stellar().account().accountExists(address);
  }

  /// Adds a trust line by using the wallet sdk, so that the user can hold the
  /// given [asset]. Requires the user's signing [userKeyPair] to
  /// sign the transaction before sending it to the Stellar Network.
  /// Returns true on success.
  static Future<bool> addAssetSupport(wallet_sdk.IssuedAssetId asset,
      wallet_sdk.SigningKeyPair userKeyPair) async {
    // build sign and submit transaction to stellar.
    var stellar = _wallet.stellar();
    var txBuilder = await stellar.transaction(userKeyPair);
    var tx = txBuilder.addAssetSupport(asset).build();
    stellar.sign(tx, userKeyPair);
    return await stellar.submitTransaction(tx);
  }

  /// Removes a trust line by using the wallet sdk, so that the user can not hold the
  /// given [asset] any more. It only works if the user has a balance of 0
  /// for the given asset. Requires the user's signing [userKeyPair] to
  /// sign the transaction before sending it to the Stellar Network.
  /// Returns true on success.
  static Future<bool> removeAssetSupport(wallet_sdk.IssuedAssetId asset,
      wallet_sdk.SigningKeyPair userKeyPair) async {
    // build sign and submit transaction to stellar.
    var stellar = _wallet.stellar();
    var txBuilder = await stellar.transaction(userKeyPair);
    var tx = txBuilder.removeAssetSupport(asset).build();
    stellar.sign(tx, userKeyPair);
    return await stellar.submitTransaction(tx);
  }

  /// Submits a transaction to the Stellar Network that funds an account
  /// for the [destinationAddress]. The [startingBalance] must be min.
  /// one XLM. The signing [userKeyPair] needed to sign the transaction before submission.
  /// The stellar address from [userKeyPair] will be used as the source account
  /// of the transaction.
  static Future<bool> createAccount(
      {required String destinationAddress,
      String? memo,
      String startingBalance = "1",
      required wallet_sdk.SigningKeyPair userKeyPair}) async {

    // Build, sign and submit transaction to stellar.
    var stellar = _wallet.stellar();
    var txBuilder = await stellar.transaction(userKeyPair);
    txBuilder = txBuilder.createAccount(
        wallet_sdk.PublicKeyPair.fromAccountId(destinationAddress),
        startingBalance: startingBalance);
    if (memo != null) {
      txBuilder = txBuilder.setMemo(core_sdk.MemoText(memo));
    }
    var tx = txBuilder.build();
    stellar.sign(tx, userKeyPair);

    return await stellar.submitTransaction(tx);
  }

  /// Submits a payment to the Stellar Network by using the wallet sdk.
  /// It requires the [destinationAddress] of the recipient, the [assetId]
  /// representing the asset to be send, [amount], optional text [memo] and
  /// the signing [userKeyPair] needed to sign the transaction before submission.
  /// The stellar address from [userKeyPair] will be used as the source account
  /// of the transaction.
  /// Returns true on success.
  static Future<bool> sendPayment(
      {required String destinationAddress,
      required wallet_sdk.StellarAssetId assetId,
      required String amount,
      String? memo,
      required wallet_sdk.SigningKeyPair userKeyPair}) async {
    // Build, sign and submit transaction to stellar.
    var stellar = _wallet.stellar();
    var txBuilder = await stellar.transaction(userKeyPair);
    txBuilder = txBuilder.transfer(destinationAddress, assetId, amount);
    if (memo != null) {
      txBuilder = txBuilder.setMemo(core_sdk.MemoText(memo));
    }
    var tx = txBuilder.build();
    stellar.sign(tx, userKeyPair);
    return await stellar.submitTransaction(tx);
  }

  /// Searches for a strict send payment path by using the wallet sdk.
  /// Requires the [sourceAsset] + [sourceAmount] and the [destinationAddress]
  /// of the recipient.
  static Future<List<wallet_sdk.PaymentPath>> findStrictSendPaymentPath(
      {required wallet_sdk.StellarAssetId sourceAsset,
      required String sourceAmount,
      required String destinationAddress}) async {
    var stellar = _wallet.stellar();
    return await stellar.findStrictSendPathForDestinationAddress(
        sourceAsset, sourceAmount, destinationAddress);
  }

  /// Searches for a strict receive payment path by using the wallet sdk.
  /// Requires the [sourceAddress] (account id of the sending account),
  /// [destinationAsset] and [destinationAmount].
  /// It will search for all source assets hold by the user.
  static Future<List<wallet_sdk.PaymentPath>> findStrictReceivePaymentPath(
      {required String sourceAddress,
      required wallet_sdk.StellarAssetId destinationAsset,
      required String destinationAmount}) async {
    var stellar = _wallet.stellar();
    return await stellar.findStrictReceivePathForSourceAddress(
        destinationAsset, destinationAmount, sourceAddress);
  }

  /// Sends a strict send path payment by using the wallet sdk.
  /// Requires the [sendAssetId] representing the asset to send,
  /// strict [sendAmount] and the [destinationAddress] of the
  /// recipient. [destinationAssetId] representing the destination asset,
  /// the [destinationMinAmount] to be received and the payment path
  /// previously obtained by [findStrictSendPaymentPath]. Optional
  /// text [memo] and and the signing [userKeyPair] needed to sign
  /// the transaction before submission.
  /// Returns true on success.
  static Future<bool> strictSendPayment(
      {required wallet_sdk.StellarAssetId sendAssetId,
      required String sendAmount,
      required String destinationAddress,
      required wallet_sdk.StellarAssetId destinationAssetId,
      required String destinationMinAmount,
      required List<wallet_sdk.StellarAssetId> path,
      String? memo,
      required wallet_sdk.SigningKeyPair userKeyPair}) async {
    // Build, sign and submit transaction to stellar.
    var stellar = _wallet.stellar();
    var txBuilder = await stellar.transaction(userKeyPair);
    txBuilder = txBuilder.strictSend(
        sendAssetId: sendAssetId,
        sendAmount: sendAmount,
        destinationAddress: destinationAddress,
        destinationAssetId: destinationAssetId,
        destinationMinAmount: destinationMinAmount,
        path: path);
    if (memo != null) {
      txBuilder = txBuilder.setMemo(core_sdk.MemoText(memo));
    }
    var tx = txBuilder.build();
    stellar.sign(tx, userKeyPair);
    return await stellar.submitTransaction(tx);
  }

  ///Sends a strict receive path payment by using the wallet sdk.
  /// Requires the [sendAssetId] representing the asset to send,
  /// [sendMaxAmount] and the [destinationAddress] of the
  /// recipient. [destinationAssetId] representing the destination asset,
  /// the strict [destinationAmount] to be received and the payment path
  /// previously obtained by [findStrictReceivePaymentPath]. Optional
  /// text [memo] and and the signing [userKeyPair] needed to sign
  /// the transaction before submission.
  /// Returns true on success.
  static Future<bool> strictReceivePayment(
      {required wallet_sdk.StellarAssetId sendAssetId,
      required String sendMaxAmount,
      required String destinationAddress,
      required wallet_sdk.StellarAssetId destinationAssetId,
      required String destinationAmount,
      required List<wallet_sdk.StellarAssetId> path,
      String? memo,
      required wallet_sdk.SigningKeyPair userKeyPair}) async {
    // Build, sign and submit transaction to stellar.
    var stellar = _wallet.stellar();
    var txBuilder = await stellar.transaction(userKeyPair);
    txBuilder = txBuilder.strictReceive(
        sendAssetId: sendAssetId,
        sendMaxAmount: sendMaxAmount,
        destinationAddress: destinationAddress,
        destinationAssetId: destinationAssetId,
        destinationAmount: destinationAmount,
        path: path);
    if (memo != null) {
      txBuilder = txBuilder.setMemo(core_sdk.MemoText(memo));
    }
    var tx = txBuilder.build();
    stellar.sign(tx, userKeyPair);
    return await stellar.submitTransaction(tx);
  }

  /// Loads the list of the 5 most recent payments for given [address].
  static Future<List<PaymentInfo>> loadRecentPayments(String address) async {
    List<PaymentInfo> recentPayments = List<PaymentInfo>.empty(growable: true);

    var accountExists = await StellarService.accountExists(address);
    if (!accountExists) {
      return recentPayments;
    }
    // fetch payments from stellar
    var server = _wallet.stellar().server;

    // loads the recent payments (max 5)
    var paymentsPage = await server.payments
        .forAccount(address)
        .order(core_sdk.RequestBuilderOrder.DESC)
        .limit(5)
        .execute();

    if (paymentsPage.records == null) {
      return recentPayments;
    }

    for (var payment in paymentsPage.records!) {
      if (payment is core_sdk.PaymentOperationResponse) {
        var direction = payment.to!.accountId == address
            ? PaymentDirection.received
            : PaymentDirection.sent;
        recentPayments.add(PaymentInfo(
            asset: wallet_sdk.StellarAssetId.fromAsset(payment.asset),
            amount: payment.amount!,
            direction: direction,
            address: direction == PaymentDirection.received
                ? payment.from!.accountId
                : payment.to!.accountId));
      } else if (payment is core_sdk.CreateAccountOperationResponse) {
        recentPayments.add(PaymentInfo(
            asset: wallet_sdk.NativeAssetId(),
            amount: payment.startingBalance!,
            direction: PaymentDirection.received,
            address: payment.funder!));
      } else if (payment
          is core_sdk.PathPaymentStrictReceiveOperationResponse) {
        var direction = payment.to == address
            ? PaymentDirection.received
            : PaymentDirection.sent;
        recentPayments.add(PaymentInfo(
            asset: wallet_sdk.StellarAssetId.fromAsset(payment.asset),
            amount: payment.amount!,
            direction: direction,
            address: direction == PaymentDirection.received
                ? payment.from!
                : payment.to!));
      } else if (payment is core_sdk.PathPaymentStrictSendOperationResponse) {
        var direction = payment.to == address
            ? PaymentDirection.received
            : PaymentDirection.sent;
        recentPayments.add(PaymentInfo(
            asset: wallet_sdk.StellarAssetId.fromAsset(payment.asset),
            amount: payment.amount!,
            direction: direction,
            address: direction == PaymentDirection.received
                ? payment.from!
                : payment.to!));
      }
    }
    return recentPayments;
  }
}

class AssetInfo {
  wallet_sdk.StellarAssetId asset;
  String balance;

  AssetInfo({required this.asset, required this.balance});
}

enum PaymentDirection { sent, received }

class PaymentInfo {
  wallet_sdk.StellarAssetId asset;
  String amount;
  PaymentDirection direction;
  String address;
  String? contactName;

  PaymentInfo(
      {required this.asset,
      required this.amount,
      required this.direction,
      required this.address,
      this.contactName});

  @override
  String toString() {
    return '${Util.removeTrailingZerosFormAmount(amount)} ${asset.id == 'native' ? 'XLM' : (asset as wallet_sdk.IssuedAssetId).code}'
        '${direction == PaymentDirection.received ? ' received from' : ' sent to'} ${contactName ?? Util.shortAddress(address)}';
  }
}
