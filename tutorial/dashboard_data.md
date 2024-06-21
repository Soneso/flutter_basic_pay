# Dashboard data

After login, the users app data is managed by [`DashboardData`](https://github.com/Soneso/flutter_basic_pay/blob/main/lib/services/data.dart).
It can load the user data from the Stellar Network, such as for example the user trusted assets and their balances or recent payments. Furthermore, it can send transactions to the Stellar Network by using the wallet sdk such as for example to add or remove a trusted asset for the user or to send a payment on behalf of the user.

To hold the loaded data in memory it uses different lists, such as for example:

```dart
/// The assets currently hold by the user.
List<AssetInfo> assets = List<AssetInfo>.empty(growable: true);

/// A list of recent payments that the user received or sent.
List<PaymentInfo> recentPayments = List<PaymentInfo>.empty(growable: true);

/// The list of contacts that the user stored locally.
List<ContactInfo> contacts = List<ContactInfo>.empty(growable: true);
```

Widgets can subscribe for streaming events that are handled by different `StreamController` instances. E.g. 

```dart
/// Stream controller that broadcasts updates within the list of
/// assets owned by the user. Such as asset added, asset removed,
/// asset balance changed.
final StreamController<List<AssetInfo>> _assetsInfoStreamController =
    StreamController<List<AssetInfo>>.broadcast();

//...
/// Subscribe for updates on the list of assets the user holds.
/// E.g. asset added, balance changed.
Stream<List<AssetInfo>> subscribeForAssetsInfo() =>
    _assetsInfoStreamController.stream;

```

If the data has changed, for example after loading the assets from the Stellar Network, corresponding events are emitted,
so that the listening widgets can be updated.

```dart
/// Emit updates on the list of assets the user holds.
/// E.g. asset added, balance changed.
void _emitAssetsInfo() {
    _assetsInfoStreamController.add(assets);
}
```

Example: loading assets from the Stellar network:

```dart
/// The assets currently hold by the user.
List<AssetInfo> assets = List<AssetInfo>.empty(growable: true);

//...

/// Loads the users assets from the Stellar Network
Future<List<AssetInfo>> loadAssets() async {
    assets = await StellarService.loadAssetsForAddress(userAddress);
    _emitAssetsInfo();
    return assets;
}
```

In [StellarService](https://github.com/Soneso/flutter_basic_pay/blob/main/lib/services/stellar.dart) :

```dart
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
```

## Next

Continue with [Account creation](account_creation.md)