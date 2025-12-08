import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:landmark_records/landmark_provider.dart';
import 'package:landmark_records/overview_screen.dart';
import 'package:landmark_records/records_screen.dart';
import 'package:landmark_records/new_entry_screen.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ChangeNotifierProvider(
      create: (context) => LandmarkProvider(),
      child: MaterialApp(
        title: 'Landmark Records',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00796B), // Dark Teal
            primary: const Color(0xFF00796B),
            secondary: const Color(0xFFFFC107), // Amber
            surface: const Color(0xFFF5F5F5), // Light Grey
            background: Colors.white,
            error: const Color(0xFFD32F2F), // Red
          ),
          textTheme: GoogleFonts.poppinsTextTheme(textTheme).copyWith(
            titleLarge: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
            titleMedium: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
            bodyMedium: GoogleFonts.poppins(fontSize: 14),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: const Color(0xFF00796B),
            foregroundColor: Colors.white,
            titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            selectedItemColor: Color(0xFF00796B),
            unselectedItemColor: Colors.grey,
          ),
        ),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  static const List<Widget> _widgetOptions = <Widget>[
    OverviewScreen(),
    RecordsScreen(),
    NewEntryScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    Provider.of<LandmarkProvider>(context, listen: false).fetchLandmarks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Landmark Records'),
        centerTitle: true,
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Records',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'New Entry',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
