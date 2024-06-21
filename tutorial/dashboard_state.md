# Dashboard state

As soon as the user is logged in, the [DashboardHomePage](https://github.com/Soneso/flutter_basic_pay/blob/main/lib/widgets/dashboard/home_page.dart) widget is displayed. It takes care of the navigation within the app and provides an instance of the `DashboardState` to the individual subpages with the help of the [provider plugin](https://pub.dev/packages/provider).

Let's have a look to the `DashboardState` class:

```dart
class DashboardState {
  final AuthService authService;
  late DashboardData data;

  DashboardState(this.authService) {
    data = DashboardData(authService.signedInUserAddress!);
  }
}
```

A new instance is initialised with the `AuthService` (see [authentication](authentication.md)) with which the user was logged in.
In the constructor, a new instance of the class [`DashboardData`](https://github.com/Soneso/flutter_basic_pay/blob/main/lib/services/data.dart) is created with the stellar address of the logged-in user. `DashboardData` provides user-related data such as the list of contacts, the user's stellar assets, recent payments and so on. We will read more details about it in the next chapter.

Now let's see how the `DashboardState` is shared:

```dart
class _DashboardHomePageState extends State<DashboardHomePage> {
  late final DashboardState _dashboardState;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _dashboardState = DashboardState(widget.auth);
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: _dashboardState,
      child: AdaptiveScaffold(
         //... Subpages
    );
  }

//...
}
```

The auth service and the current user-related data can now be accessed as follows from all subpages:

```dart
var dashboardState = Provider.of<DashboardState>(context);
```

## Next

Continue with [Dashboard data](dashboard_data.md).