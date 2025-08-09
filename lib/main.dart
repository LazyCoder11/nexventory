import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nexventory/src/screens/add_customers.dart';
import 'package:nexventory/src/screens/add_product.dart';
import 'package:nexventory/src/screens/dashboard.dart';
import 'package:nexventory/src/screens/login_screen.dart';
import 'package:nexventory/src/screens/onboard_screen.dart';
import 'package:nexventory/src/screens/signup_screen.dart';
import 'package:nexventory/src/screens/verify_email_screen.dart';
import 'package:nexventory/src/screens/warehouse.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'src/screens/create_order.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

bool _supabaseInitialized = false; // ✅ New global flag

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // GREEN COLOR : 0xFF98FB98

  if (!_supabaseInitialized) {
    await Supabase.initialize(
      url: 'https://ofhmwonavzqylclxgdnk.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9maG13b25hdnpxeWxjbHhnZG5rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg1ODc4MjYsImV4cCI6MjA2NDE2MzgyNn0.yyU0tjMbp56VdnWmNV9iY_JY5IpUTey6sBZxyOIDT4k',
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    _supabaseInitialized = true; // ✅ Mark as initialized
  }

  final session = Supabase.instance.client.auth.currentSession;
  final initialRoute = session != null ? '/home' : '/onboarding';

  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final session = data.session;
    final event = data.event;

    if (event == AuthChangeEvent.signedIn && session != null) {
      // Automatically redirected after email confirmation
      navigatorKey.currentState?.pushReplacementNamed('/home');
    }
  });

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String? initialRoute;
  const MyApp({super.key, this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NexVentory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xFF98AFFB),
        fontFamily: 'MintGrotesk',
      ),
      // {---------------------------------------------------------- ALL THE ROUTES -----------------------------------------------------------------}
      initialRoute: initialRoute ?? '/onboarding',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/onboarding':
            return createSlideRoute(const OnboardScreen());
          case '/login':
            return createSlideRoute(LoginScreen());
          case '/signup':
            return createSlideRoute(SignupScreen());
          case '/home':
            return createSlideRoute(const MyHomePage());
          case '/verify-email':
            return createSlideRoute(const VerifyEmailScreen());
          default:
            return null; // Or a default route
        }
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _titles = [
    'Dashboard',
    'Create Order',
    'Home',
    'Team',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _titles.length, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // To update the AppBar title
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleLogout() async {
    final supabase = Supabase.instance.client;

    try {
      await supabase.auth.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Logged out")));

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false, // Remove all previous routes
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Logout failed: ${e.toString()}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Color(
          0xFF98AFFB,
        ), // Transparent to blend with curved UI
        statusBarIconBrightness:
            Brightness.dark, // Light icons for dark background
        systemNavigationBarColor: Color(0xFF98AFFB),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: AppBar(
            backgroundColor: const Color(0xFF98AFFB),
            automaticallyImplyLeading: false,
            elevation: 0,
            flexibleSpace: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0),
                      child: Row(
                        children: [
                          Icon(Icons.eco, size: 34, color: Colors.black),
                          SizedBox(width: 8),
                          Text(
                            'NexVentory',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: GestureDetector(
                        onTap: _handleLogout,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.all(
                              Radius.circular(100),
                            ),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            Icons.logout_rounded,
                            color: Color(0xFF98AFFB),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.black),
                left: BorderSide(color: Colors.black),
                right: BorderSide(color: Colors.black),
                bottom: BorderSide(color: Colors.black),
              ),
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(30)),
            ),
            child: TabBarView(
              controller: _tabController,
              children: [
                Dashboard(),
                AddProduct(),
                CreateOrderScreen(),
                AddCustomer(),
                WarehouseScreen(),
              ],
            ),
          ),
        ),

        bottomNavigationBar: Material(
          color: Colors.white,
          child: Container(
            height: 70,
            decoration: const BoxDecoration(color: Color(0xFF98AFFB)),
            child: TabBar(
              controller: _tabController,
              indicator: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.black, width: 3.0),
                ),
              ),
              labelColor: Color(0xFF0C1B2C),
              unselectedLabelColor: Color(0xFF0C1B2C),
              indicatorColor: Colors.white,
              dividerColor: Colors.transparent,
              tabs: [
                const Tab(icon: Icon(Icons.home)),
                Tab(icon: Icon(MdiIcons.cart)),
                Tab(icon: Icon(MdiIcons.plusCircle)),
                Tab(icon: Icon(MdiIcons.accountGroup)),
                Tab(icon: Icon(MdiIcons.packageVariant)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Route createSlideRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offsetAnimation = Tween<Offset>(
        begin: const Offset(1.0, 0.0), // Slide in from right
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));

      return SlideTransition(position: offsetAnimation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 1000),
  );
}
