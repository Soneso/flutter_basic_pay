import 'package:flutter/material.dart';
import 'package:flutter_basic_pay/services/data.dart';
import 'package:flutter_basic_pay/widgets/common/dialogs.dart';
import 'package:flutter_basic_pay/widgets/common/navigation_service.dart';
import 'package:flutter_basic_pay/widgets/dashboard/home_page.dart';
import 'package:provider/provider.dart';

class KYCInformationPage extends StatelessWidget {
  const KYCInformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    var dashboardState = Provider.of<DashboardState>(context);
    return FutureBuilder<Map<String, String>>(
      future: dashboardState.data.loadKycData(),
      builder: (context, futureSnapshot) {
        if (!futureSnapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return StreamBuilder<Map<String, String>>(
          initialData: futureSnapshot.data,
          stream: dashboardState.data.subscribeForKycData(),
          builder: (context, snapshot) {
            if (snapshot.data == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            return KYCInformationPageBody(
              kycData: snapshot.data!.entries,
              data: dashboardState.data,
            );
          },
        );
      },
    );
  }
}

class _KYCListItem extends ListTile {
  _KYCListItem(MapEntry entry, ValueChanged<MapEntry> onEdit)
      : super(
            title: Text(entry.key.replaceAll('_', ' ').toUpperCase()),
            subtitle: Text(entry.value),
            key: ObjectKey(entry),
            trailing: IconButton(
                onPressed: () async => onEdit(entry),
                icon: const Icon(Icons.edit)));
}

class KYCInformationPageBody extends StatelessWidget {
  final Iterable<MapEntry> kycData;
  final DashboardData data;

  const KYCInformationPageBody({
    required this.kycData,
    required this.data,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("KYC Data", style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemBuilder: (context, index) {
              return Dismissible(
                background: Container(
                  color: Colors.red,
                ),
                key: ObjectKey(kycData.elementAt(index)),
                child: _KYCListItem(kycData.elementAt(index), _handleOnEdit),
              );
            },
            itemCount: kycData.length,
          ),
        ),
      ],
    );
  }

  void _handleOnEdit(MapEntry entry) async {
    if (entry.key is String && entry.value is String) {
      var newValue = await Dialogs.editValueDialog(
          entry.key.replaceAll('_', ' ').toUpperCase(),
          entry.value,
          NavigationService.navigatorKey.currentContext!);
      if (newValue != null) {
        await data.updateKycDataEntry(entry.key, newValue);
      }
    }
  }
}
