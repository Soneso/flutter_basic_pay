import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_basic_pay/api/api.dart';
import 'package:flutter_basic_pay/storage/storage.dart';
import 'package:flutter_basic_pay/widgets/dashboard/home_page.dart';
import 'package:flutter_basic_pay/widgets/dashboard/payments/path_payments_body.dart';
import 'package:flutter_basic_pay/widgets/dashboard/payments/simple_payments_body.dart';
import 'package:provider/provider.dart';

class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

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
          builder: (context, assetsSnapshot) {
            if (assetsSnapshot.data == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            return FutureBuilder<List<ContactInfo>>(
              future: dashboardState.data.loadContacts(),
              builder: (context, futureSnapshot) {
                if (!futureSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                return StreamBuilder<List<ContactInfo>>(
                  initialData: futureSnapshot.data,
                  stream: dashboardState.data.subscribeForContacts(),
                  builder: (context, contactsSnapshot) {
                    if (contactsSnapshot.data == null) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    var key = List<Object>.empty(growable: true);
                    key.addAll(assetsSnapshot.data!);
                    key.addAll(contactsSnapshot.data!);
                    return PaymentsPageBody(key: ObjectKey(key));
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class PaymentsPageBody extends StatefulWidget {
  const PaymentsPageBody({
    super.key,
  });

  @override
  State<PaymentsPageBody> createState() => _PaymentsPageBodyState();
}

class _PaymentsPageBodyState extends State<PaymentsPageBody> {
  bool waitForAccountFunding = false;
  bool pathPayment = false;
  @override
  Widget build(BuildContext context) {
    var dashboardState = Provider.of<DashboardState>(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Payments", style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
        Expanded(
          child: Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
              child: dashboardState.data.assets.isEmpty
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
                            dashboardState.data.fundUserAccount();
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
                  : SingleChildScrollView(
                      child: Container(
                        decoration: const BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.lightBlue,
                              blurRadius: 50.0,
                            ),
                          ],
                        ),
                        child: Card(
                          margin: const EdgeInsets.all(20.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                AutoSizeText(
                                  "Here you can send payments to other Stellar addresses.",
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),
                                const Divider(
                                  color: Colors.blue,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                        "Send and receive different assets?"),
                                    Switch(
                                      value: pathPayment,
                                      onChanged: (value) {
                                        setState(() {
                                          pathPayment = value;
                                        });
                                      },
                                    )
                                  ],
                                ),
                                const Divider(
                                  color: Colors.blue,
                                ),
                                const SizedBox(height: 10),
                                pathPayment
                                    ? const PathPaymentsBodyContent()
                                    : const SimplePaymentsPageBodyContent()
                              ],
                            ),
                          ),
                        ),
                      ),
                    )),
        ),
      ],
    );
  }
}
