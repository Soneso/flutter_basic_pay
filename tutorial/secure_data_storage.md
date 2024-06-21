# Secure data storage

 Flutter Basic pay is a non-custodial app. The user's private data is stored locally and securely on the user's device. It is never shared with other applications or services. Private data that is stored is the user's Stellar secret key and the list of their contacts.

## Secret key
Owning a Stellar account means possessing a key for that account. That key is made up of two parts: the public key, which you share with others, and the secret key, which you keep to yourself. This is what the secret key looks like. It starts with an S:

`SB3MIS23KDF67IGB6YH2IZKE4W6UMICIEL7JYQCL5DZUM4ZM4VUBMUF3`

On the Stellar network, the secret key that defines your account address is called the master key. By default, when you create a new account on the network, the master key is the sole signer on that account: it's the only key that can authorize transactions.


 ## Code implementation

To store the user's private data, we have built the [`SecureStorage`](https://github.com/Soneso/flutter_basic_pay/blob/main/lib/services/storage.dart) class. 
It uses the [flutter_secure_storage package](https://pub.dev/packages/flutter_secure_storage) plugin, which has been added to the dependencies in [pubspec.yaml](https://github.com/Soneso/flutter_basic_pay/blob/main/pubspec.yaml). With this plugin we can store key value pairs in the secure storage of the device.


### The user`s public and secret key

We sotore only the secret key, becaust the public key can be derived from it. To store the user's Stellar secret key, the following storage key is defined:

```dart
static const _userSecretStorageKey = 'secret';
```

The [`SecureStorage`](https://github.com/Soneso/flutter_basic_pay/blob/main/lib/services/storage.dart) class offers the following static methods to handle the storage and retrieval of the user's secret key:

```dart
static storeUserKeyPair(wallet_sdk.SigningKeyPair userKeyPair, String pin)
static Future<bool> hasUser()
static Future<wallet_sdk.SigningKeyPair> getUserKeyPair(String pin)
```

Let's now look at their implementation.

```dart
/// Stores the signing [userSigningKeyPair] to secure storage. Uses the [pin] to
/// cryptographically encode the secret key before storing it, so that
/// it can only be retrieved by the user who knows the pin.
static storeUserKeyPair(wallet_sdk.SigningKeyPair userSigningKeyPair, String pin) async {
    const FlutterSecureStorage storage = FlutterSecureStorage();

    // encrypt the secret key before saving it, so that only the user can decrypt it.
    var encryptedSecretKey = AesHelper.encrypt(pin, userSigningKeyPair.secretKey);
    await storage.write(key: _userSecretStorageKey, value: encryptedSecretKey);
}
```

As parameters we need the users signing keypair and their pin. The user signing keypair is transferred with the help of the wallet sdk class `SigningKeyPair`. The instance contains the user's Stellar public key and secret key. By using the `SigningKeyPair` class we can make sure that the contained secret key is a valid secret key. We also need the user's pin to encrypt the secret key, so that only the user themselves can decrypt it later with the help of their pin.

Before saving the secret key in the secure storage, we encrypt it with the user's pin. This guarantees that even our app can only access it later with the user's pin. 

The secret key is required to sign stellar transactions, such as payment transactions. This means that we will need the user's permission for every transaction that we want to sign. The user must enter their pin on request, so that we can decrypt the secret key to sign the transaction for the user.

To find out whether we have already stored user data in the secure storage, we have implemented the method `hasUser`:

```dart
/// Returns true if secure user data is stored in the storage.
static Future<bool> hasUser() async {
    const FlutterSecureStorage storage = FlutterSecureStorage();
    return await storage.containsKey(key: _userSecretStorageKey);
}
```

It simply checks whether an entry already exists for our `_userSecretStorageKey`.

To load the user data we have implemented the method `getUserKeypair`:

```dart
/// Returns the signing user keypair from the storage. Requires the
/// user's [pin] to decode the stored user's secret key. It can only construct
/// the keypair if there is user data in the storage (see [hasUser]) and
/// if the given [pin] is valid. Throws [UserNotFound] if the user data could
/// not be found in the secure storage. Throws [InvalidPin] if the pin
/// is invalid and the data could not be decrypted.
static Future<wallet_sdk.SigningKeyPair> getUserKeyPair(String pin) async {
    const FlutterSecureStorage storage = FlutterSecureStorage();
    var encryptedUserSecret = await storage.read(key: _userSecretStorageKey);
    if (encryptedUserSecret == null) {
        throw UserNotFound();
    }
    // decrypt user secret key with pin
    try {
        var userSecretKey = AesHelper.decrypt(pin, encryptedUserSecret);
        return wallet_sdk.SigningKeyPair.fromSecret(userSecretKey);
    } catch (e) {
        throw InvalidPin();
    }
}
```

First we try to read the encrypted secret key from the storage. If not found we throw a `UserNotFound` exception. Then we try to decrypt it with the given pin that has been requested from the user. If the pin is valid, we can decrypt it and create a `SigningKeyPair` from it by using the wallet sdk. If the pin is invalid, this will fail and we throw an `InvalidPin` exception.


### Contacts list

To save the user's contact list, the following storage key is defined:

```dart
static const _contactsStorageKey = 'contacts';
```

The [`SecureStorage`](https://github.com/Soneso/flutter_basic_pay/blob/main/lib/services/storage.dart) offers the following public static methods for manipulating the data:

```dart
static Future<List<ContactInfo>> addContact(ContactInfo contact)
static Future<List<ContactInfo>> getContacts()
static Future<List<ContactInfo>> removeContact(String contactName)
```

A contact is represented by the class `ContactInfo`:

```dart
class ContactInfo {
  String name;
  String address;

  ContactInfo(this.name, this.address);

  factory ContactInfo.fromJson(Map<String, dynamic> json) => ContactInfo(
        json['name'],
        json['address'],
      );

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
    };
  }
}
```

It holds the contact`s name (e.g. `John`) and the contact's Stellar address (account id). The data is stored in the secure storage as a json string.

Next, let's see how we store a new contact:

```dart
/// Stores a new user [contact]. If the contact (name) already exists,
/// it will be overridden.
static Future<List<ContactInfo>> addContact(ContactInfo contact) async {
    var contacts = await getContacts();
    contacts.removeWhere((item) => item.name == contact.name);
    contacts.add(contact);
    await _saveContacts(contacts);
    return contacts;
}
```

First we load the list of contacts already stored and check whether there is already a contact with the name of the new contact. If so, we delete the old one first. Then we add our new contact and save the list with the private `_saveContacts` method:

```dart
/// Saves the list of contacts to storage as a json string.
static Future<void> _saveContacts(List<ContactInfo> contacts) async {
    var valArr = List<Map<String, dynamic>>.empty(growable: true);
    for (var contract in contacts) {
        valArr.add(contract.toJson());
    }
    Map<String, dynamic> jsonContacts = {'contacts': valArr};
    var data = json.encode(jsonContacts);

    const FlutterSecureStorage storage = FlutterSecureStorage();
    await storage.write(key: _contactsStorageKey, value: data);
}
```

First we create a json string that contains all contacts and then we save it in the secure storage with the key: `_contactsStorageKey`.

Next, let's see how we load the contacts list from the secure storage:

```dart
/// Loads the user contacts from secure storage.
static Future<List<ContactInfo>> getContacts() async {
    List<ContactInfo> contacts = List<ContactInfo>.empty(growable: true);
    const FlutterSecureStorage storage = FlutterSecureStorage();
    var contactsJson = await storage.read(key: _contactsStorageKey);
    if (contactsJson != null) {
        var data = json.decode(contactsJson);
        contacts = List<ContactInfo>.from(
            data['contacts'].map((e) => ContactInfo.fromJson(e)));
    }
    return contacts;
}
```

If we find the json string for the key: `_contactsStorageKey` in the secure storage, we create a contact list from it. Otherwise we return an empty contact list.

To remove a contact we implemented following method:

```dart
/// Removes a user contact from storage for the given [contactName].
static Future<List<ContactInfo>> removeContact(String contactName) async {
    var contacts = await getContacts();
    contacts.removeWhere((item) => item.name == contactName);
    await _saveContacts(contacts);
    return contacts;
}
```

The contact name must be passed as a parameter. First we load the list of contacts, then we delete the contact with the specified name if it exists.
Then we store the changed list.

## Next

Continue with [Authentication](authentication.md).