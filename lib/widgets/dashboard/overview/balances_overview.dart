import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_basic_pay/api/api.dart';
import 'package:flutter_basic_pay/util/util.dart';
import 'package:flutter_basic_pay/widgets/dashboard/home_page.dart';
import 'package:provider/provider.dart';
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart';

class BalancesOverview extends StatelessWidget {
  const BalancesOverview({super.key});

  @override
  Widget build(BuildContext context) {
    var dashboardState = Provider.of<DashboardState>(context);
    return FutureBuilder<List<AssetInfo>>(
      future: dashboardState.data.loadAssets(),
      builder: (context, futureSnapshot) {
        if (!futureSnapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return StreamBuilder<List<AssetInfo>>(
          initialData: futureSnapshot.data,
          stream: dashboardState.data.subscribeForAssetsInfo(),
          builder: (context, snapshot) {
            if (snapshot.data == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            return BalancesOverviewBody(
                assets: snapshot.data!.reversed.toList(),
                onFundAccount: () async =>
                    dashboardState.data.fundUserAccount());
          },
        );
      },
    );
  }
}

class BalancesOverviewBody extends StatefulWidget {
  final List<AssetInfo> assets;
  final VoidCallback onFundAccount;

  const BalancesOverviewBody(
      {required this.assets, required this.onFundAccount, super.key});

  @override
  State<BalancesOverviewBody> createState() => _BalancesOverviewBodyState();
}

class _BalancesOverviewBodyState extends State<BalancesOverviewBody> {
  bool waitForAccountFunding = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Asset Balances",
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
        Expanded(
          // Load the initial snapshot using a FutureBuilder, and subscribe to
          // additional updates with a StreamBuilder.
          child: Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
              child: widget.assets.isEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            "Your account does not exist on the Stellar Test Network and needs to be funded!",
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () async {
                            if (waitForAccountFunding) {
                              return;
                            }
                            setState(() {
                              waitForAccountFunding = true;
                            });
                            widget.onFundAccount();
                          },
                          child: waitForAccountFunding
                              ? const SizedBox(
                                  height: 15,
                                  width: 15,
                                  child: CircularProgressIndicator(),
                                )
                              : const Text('Fund on testnet',
                                  style: TextStyle(color: Colors.purple)),
                        ),
                      ],
                    )
                  : Balances(widget.assets)),
        ),
      ],
    );
  }
}

class Balances extends StatelessWidget {
  final List<AssetInfo> assets;

  const Balances(this.assets, {super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.start,
      direction: Axis.horizontal,
      spacing: 10,
      children: [
        ...assets.map(
          (asset) => BalanceCard(asset),
        )
      ],
    );
  }
}

class BalanceCard extends StatelessWidget {
  final AssetInfo asset;

  const BalanceCard(this.asset, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: asset.asset is NativeAssetId
          ? Colors.blue[200]
          : Colors.lightGreen[200],
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: asset.asset is NativeAssetId
            ? AutoSizeText(
                "XML: ${Util.removeTrailingZerosFormAmount(asset.balance)}",
                style: Theme.of(context).textTheme.bodyLarge)
            : asset.asset is IssuedAssetId
                ? AutoSizeText(
                    "${(asset.asset as IssuedAssetId).code}: ${Util.removeTrailingZerosFormAmount(asset.balance)}",
                    style: Theme.of(context).textTheme.bodyLarge)
                : const SizedBox(height: 10),
      ),
    );
  }
}
