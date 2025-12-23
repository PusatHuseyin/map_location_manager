import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'locations/locations_screen.dart';
import 'map/map_screen.dart';
import 'routes/routes_screen.dart';
import '../providers/theme_provider.dart';
import '../providers/location_provider.dart';
import '../providers/routes_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 1;

  final List<Widget> _screens = const [
    LocationsScreen(),
    MapScreen(),
    RoutesScreen(),
  ];

  final List<String> _titles = const ['Konumlar', 'Harita', 'Rotalar'];

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final routesProvider = context.watch<RoutesProvider>();

    // Konum haritada gosterilecekse
    if (locationProvider.shouldNavigateToMap) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _currentIndex = 1);
        locationProvider.consumeNavigation();
      });
    }

    // Rota haritada gosterilecekse
    if (routesProvider.shouldNavigateToMap) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _currentIndex = 1);
        routesProvider.consumeNavigation();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDark(context)
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Konumlar',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Harita'),
          BottomNavigationBarItem(icon: Icon(Icons.route), label: 'Rotalar'),
        ],
      ),
    );
  }
}
