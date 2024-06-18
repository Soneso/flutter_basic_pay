import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_basic_pay/api/api.dart';
import 'package:flutter_basic_pay/storage/storage.dart';
import 'package:flutter_basic_pay/widgets/dashboard/home_page.dart';
import 'package:provider/provider.dart';

class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    var dashboardState = Provider.of<DashboardState>(context);
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
          builder: (context, snapshot) {
            if (snapshot.data == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            return ContactsPageBody(
              userContacts: snapshot.data!.reversed.toList(),
              data: dashboardState.data,
            );
          },
        );
      },
    );
  }
}

class _ContactListItem extends ListTile {
  _ContactListItem(ContactInfo contact)
      : super(
            title: Text(contact.name),
            subtitle: Text(contact.address),
            key: ObjectKey(contact),
            trailing: IconButton(
                onPressed: () async =>
                    await FlutterClipboard.copy(contact.address),
                icon: const Icon(Icons.copy)));
}

class ContactsPageBody extends StatelessWidget {
  final List<ContactInfo> userContacts;
  final DashboardData data;

  const ContactsPageBody({
    required this.userContacts,
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
              Text("Contacts", style: Theme.of(context).textTheme.titleLarge),
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
                key: ObjectKey(userContacts[index]),
                onDismissed: (DismissDirection direction) {
                  data.removeContact(userContacts[index].name);
                },
                child: _ContactListItem(userContacts[index]),
              );
            },
            itemCount: userContacts.length,
          ),
        ),
      ],
    );
  }
}
