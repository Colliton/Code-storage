import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart'; // do otwierania linków LinkedIn
import 'package:table_calendar/table_calendar.dart';

void main() {
  runApp(WomanInStemApp());
}

class WomanInStemApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Woman In STEM',
      theme: ThemeData(
        primaryColor: Color(0xFF2D2A4A),
        scaffoldBackgroundColor: Color(0xFFF2E9DC),
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF2D2A4A)),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF2D2A4A),
          titleTextStyle: TextStyle(
            color: Color(0xFFF2E9DC), // Twój najjaśniejszy kolor
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
          elevation: 4,
        ),
      ),
      home: MainScreen(),
    );
  }
}


class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Aktualnie wybrany ekran
  int _selectedIndex = 0;


  List<Widget> get _pages => [
    HomePage(onTileTap: _onTileTapped, tiles: _tiles),
    CoursesPage(
      onBack: () {
        setState(() {
          _selectedIndex = 0;
        });
      },
    ),
    ForumPage(),
    EventsPage(),
    LeaderOfTheWeekPage(
      onBack: () {
        setState(() {
          _selectedIndex = 0;
        });
      },
    ),
    // MentalHealthPage(...)
  ];



  // Etykiety kafelków i ikony
  final List<Map<String, dynamic>> _tiles = [
    {'title': 'Courses', 'icon': Icons.school},
    {'title': 'Forum', 'icon': Icons.forum},
    {'title': 'Events', 'icon': Icons.event},
    {'title': 'Leader of the Week', 'icon': Icons.star},
    {'title': 'Contact', 'icon':Icons.phone}
  ];

  void _onTileTapped(int index) {
    if (index == _tiles.length - 1) { // ostatni kafelek to Contact
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ContactPage()),
      );
    } else {
      setState(() {
        _selectedIndex = index + 1; // +1 bo 0 to HomePage
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Woman In STEM'),
        backgroundColor: Color(0xFF2D2A4A),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF2D2A4A),
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Color(0xFFF2E9DC),
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                // Tutaj nawigacja do profilu
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => ProfilePage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => SettingsPageWrapper()));
              },
            ),
            ListTile(
              leading: Icon(Icons.favorite),
              title: Text('Mental Health'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => MentalHealthPage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.help),
              title: Text('Help'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => HelpPage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Log Out'),
              onTap: () {
                Navigator.pop(context); // Zamknij drawer, jeśli dotyczy
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('You have been successfully logged out.'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },

            ),
          ],
        ),
      ),
      body: _selectedIndex == 0
          ? HomePage(
        onTileTap: _onTileTapped,
        tiles: _tiles,
      )
          : _pages[_selectedIndex],
    );
  }
}

// --- Ekran główny ---

class HomePage extends StatelessWidget {
  final void Function(int)? onTileTap;
  final List<Map<String, dynamic>>? tiles;

  HomePage({this.onTileTap, this.tiles});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Header z Liderką tygodnia
          LeaderHeader(),

          SizedBox(height: 24),

          // Opis twórców i misji
          MissionDescription(),

          SizedBox(height: 24),

          // Kafelki
          Expanded(
            child: GridView.builder(
              itemCount: tiles?.length ?? 0,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1),
              itemBuilder: (context, index) {
                final tile = tiles![index];
                return GestureDetector(
                  onTap: () {
                    if (onTileTap != null) onTileTap!(index);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFEFC7C2),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(tile['icon'], size: 48, color: Color(0xFF2D2A4A)),
                        SizedBox(height: 8),
                        Text(
                          tile['title'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D2A4A)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class LeaderHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Przykładowe dane liderki (potem dynamiczne)
    final leaderName = 'Anna Kowalska';
    final leaderDescription =
        'Leader in STEM inspiring women around the world.';

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF2D2A4A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(
                'https://randomuser.me/api/portraits/women/44.jpg'), // przykładowe zdjęcie
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leaderName,
                  style: TextStyle(
                      color: Color(0xFFF2E9DC),
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  leaderDescription,
                  style: TextStyle(color: Color(0xFFF2E9DC), fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MissionDescription extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF2D2A4A);

    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.15),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                width: 120,
                child: Image.asset(
                  'assets/images/Logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Woman In STEM is a community dedicated to empowering women in science, technology, engineering, and mathematics. Our mission is to inspire, connect, and support women through education, mentorship, and events.',
                style: TextStyle(fontSize: 16, color: primaryColor),
                textAlign: TextAlign.left,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



// --- Puste ekrany do dalszej rozbudowy ---

class Course {
  final String id;
  final String title;
  final String shortDescription;
  final String fullDescription;
  final int hours;
  final int videos;
  final String imagePath;
  final String category; // np. 'Mathematics', 'Programming'

  Course({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.fullDescription,
    required this.hours,
    required this.videos,
    required this.imagePath,
    required this.category,
  });
}

// Lista kategorii STEM
const List<String> stemCategories = [
  'All',
  'Mathematics',
  'Programming',
  'Biotechnology',
  'Physics',
  'Chemistry',
];

// Przykładowa lista kursów
final List<Course> courses = [
  Course(
    id: '1',
    title: 'Intro to Python',
    shortDescription: 'Learn the basics of Python programming.',
    fullDescription: 'This course covers variables, loops, functions, and more.',
    hours: 10,
    videos: 25,
    imagePath: 'assets/images/Python.png',
    category: 'Programming',
  ),
  Course(
    id: '2',
    title: 'Linear Algebra',
    shortDescription: 'Vectors, matrices and linear transformations.',
    fullDescription: 'Deep dive into vector spaces, eigenvalues, and more.',
    hours: 12,
    videos: 30,
    imagePath: 'assets/images/Maths.png',
    category: 'Mathematics',
  ),
  Course(
    id: '3',
    title: 'Basic Biotechnology',
    shortDescription: 'Introduction to biotech principles.',
    fullDescription: 'Learn about DNA, proteins, and genetic engineering.',
    hours: 8,
    videos: 20,
    imagePath: 'assets/images/Biotechnology.png',
    category: 'Biotechnology',
  ),
  // więcej kursów...
];

class CoursesPage extends StatefulWidget {
  final VoidCallback? onBack;

  CoursesPage({this.onBack});

  @override
  _CoursesPageState createState() => _CoursesPageState();
}


class _CoursesPageState extends State<CoursesPage> {
  String selectedCategory = 'All';


  @override
  Widget build(BuildContext context) {
    final filteredCourses = selectedCategory == 'All'
        ? courses
        : courses.where((c) => c.category == selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Courses'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFFF2E9DC)),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedCategory,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    selectedCategory = val;
                  });
                }
              },
              items: stemCategories
                  .map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat),
              ))
                  .toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredCourses.length,
              itemBuilder: (context, index) {
                final course = filteredCourses[index];
                return ListTile(
                  leading: Image.asset(course.imagePath,
                      width: 50, height: 50, fit: BoxFit.cover),
                  title: Text(course.title),
                  subtitle: Text(course.shortDescription),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseDetailsPage(course: course),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CourseDetailsPage extends StatelessWidget {
  final Course course;

  const CourseDetailsPage({required this.course});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(course.title),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(course.imagePath,
                width: double.infinity, height: 180, fit: BoxFit.cover),
            SizedBox(height: 16),
            Text(course.fullDescription),
            SizedBox(height: 16),
            Text('Hours: ${course.hours}'),
            Text('Videos: ${course.videos}'),
          ],
        ),
      ),
    );
  }
}


class ForumPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Forum Page - to be implemented'));
  }
}

class EventsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Events Page - to be implemented'));
  }
}


class LeaderOfTheWeekPage extends StatelessWidget {
  final VoidCallback onBack;

  final String leaderName = 'Anna Kowalska';
  final String leaderDescription =
      'Anna Kowalska is an outstanding leader and mentor in the STEM field who continuously inspires young women to pursue their passions in science and technology. With many years of experience working on innovative research projects and advocating for equality in academia, Anna supports the development of new talents by promoting diversity and inclusion. Her dedication to education and knowledge sharing through numerous workshops, lectures, and mentoring programs makes her a true ambassador for change in the STEM community.';
  final String leaderEmail = 'anna.kowalska@example.com';
  final String leaderDate = '01-07 June 2025';
  final String qaLink = 'https://example.com/leader-qa';

  LeaderOfTheWeekPage({required this.onBack, Key? key}) : super(key: key);


  // Funkcja do otwierania linków
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  // Funkcja do otwierania maila
  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw 'Could not launch email client';
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF2D2A4A);
    final beigeColor = Color(0xFFF5F5DC);

    return Scaffold(
      appBar: AppBar(
        title: Text('Leader of the Week'),
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: beigeColor),
          onPressed: onBack,  // tu zamiast Navigator.pop
          tooltip: 'Back',
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(
                'https://randomuser.me/api/portraits/women/44.jpg',
              ),
            ),
            SizedBox(height: 20),
            Text(
              leaderName,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 12),
            Text(
              leaderDescription,
              style: TextStyle(
                fontSize: 16,
                color: primaryColor.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),

            // Data
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, color: primaryColor),
                SizedBox(width: 8),
                Text(
                  leaderDate,
                  style: TextStyle(
                    fontSize: 16,
                    color: primaryColor,
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // E-mail (klikalny)
            InkWell(
              onTap: () => _launchEmail(leaderEmail),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.email, color: primaryColor),
                  SizedBox(width: 8),
                  Text(
                    leaderEmail,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blueAccent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Link do Q&A
            ElevatedButton.icon(
              icon: Icon(Icons.question_answer),
              label: Text('Go to Q&A'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: TextStyle(fontSize: 18),
              ),
              onPressed: () => _launchUrl(qaLink),
            ),
          ],
        ),
      ),
    );
  }
}




class ContactPage extends StatelessWidget {
  final Color primaryColor = const Color(0xFF2D2A4A);
  final Color backgroundColor = const Color(0xFFF2E9DC);

  ContactPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Contact'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: backgroundColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Email', primaryColor),
            _sectionContent('contact@womaninstem.com', primaryColor),
            const SizedBox(height: 20),

            _sectionTitle('Phone', primaryColor),
            _sectionContent('+1 234 567 890', primaryColor),
            const SizedBox(height: 20),

            _sectionTitle('Helpline hours', primaryColor),
            _sectionContent('Mon - Fri: 9:00 AM - 5:00 PM', primaryColor),
            const SizedBox(height: 30),

            _sectionTitle('Contact form', primaryColor),
            const SizedBox(height: 12),

            _buildTextField(label: 'Your Name'),
            const SizedBox(height: 12),
            _buildTextField(label: 'Your Email', keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _buildTextField(label: 'Message', maxLines: 5),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Message sent (not implemented)')),
                  );
                },
                child: const Text(
                  'Send',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
    );
  }

  Widget _sectionContent(String content, Color color) {
    return Text(
      content,
      style: TextStyle(fontSize: 16, color: color),
    );
  }

  Widget _buildTextField({required String label, int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}



class ProfilePage extends StatelessWidget {
  final String imageUrl = 'https://example.com/photo.jpg';
  final String firstName = 'Anna';
  final String lastName = 'Kowalska';
  final String description = 'Passion for STEM and supporting women in science.';
  final String linkedInUrl = 'https://www.linkedin.com/in/anna-kowalska/';

  void _launchLinkedIn() async {
    final uri = Uri.parse(linkedInUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print('LinkedIn link cannot be opened');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Color(0xFF2D2A4A);
    final background = Color(0xFFF2E9DC);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 4,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: background),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Profil',
          style: TextStyle(
            color: background,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 400),
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.2),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundImage: NetworkImage(imageUrl),
                    backgroundColor: background.withOpacity(0.5),
                  ),
                  SizedBox(height: 24),
                  Text(
                    '$firstName $lastName',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                  SizedBox(height: 12),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontStyle: FontStyle.italic,
                        color: primary.withOpacity(0.7),
                      ),
                    ),
                  SizedBox(height: 30),
                  if (linkedInUrl.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.link, color: primary),
                        label: Text(
                          'LinkedIn',
                          style: TextStyle(color: primary),
                        ),
                        onPressed: _launchLinkedIn,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primary, width: 2),
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final Function(Locale) onLocaleChanged;

  const SettingsPage({
    Key? key,
    required this.onThemeChanged,
    required this.onLocaleChanged,
  }) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isDarkMode = false;
  bool notificationsEnabled = true;
  String selectedLanguage = 'en';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: isDarkMode,
            onChanged: (val) {
              setState(() {
                isDarkMode = val;
              });
              widget.onThemeChanged(isDarkMode ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            value: notificationsEnabled,
            onChanged: (val) {
              setState(() {
                notificationsEnabled = val;
              });
            },
          ),
          ListTile(
            title: const Text('Language'),
            trailing: DropdownButton<String>(
              value: selectedLanguage,
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'pl', child: Text('Polski')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    selectedLanguage = val;
                  });
                  widget.onLocaleChanged(Locale(val));
                }
              },
            ),
          ),
          ListTile(
            title: const Text('Account Management'),
            subtitle: const Text('Change password (placeholder)'),
            onTap: () {
              // Możesz dodać ekran zmiany hasła
            },
          ),
          const ListTile(
            title: Text('App Version'),
            subtitle: Text('1.0.0'),
          ),
        ],
      ),
    );
  }
}

// Wrapper bez funkcjonalności – tylko wygląd
class SettingsPageWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      onThemeChanged: (_) {},
      onLocaleChanged: (_) {},
    );
  }
}


class MentalHealthPage extends StatefulWidget {
  const MentalHealthPage({Key? key}) : super(key: key);

  @override
  _MentalHealthPageState createState() => _MentalHealthPageState();
}

class _MentalHealthPageState extends State<MentalHealthPage> {
  DateTime? _selectedDay;
  String? _moodMessage;

  final Color primaryColor = Color(0xFF2D2A4A);
  final Color beigeColor = Color(0xFFF5F5DC);

  String _getMoodMessage(DateTime date) {
    final day = date.day % 28; // symulacja 28-dniowego cyklu

    if (day >= 1 && day <= 5) {
      return 'Menstrual phase – You might feel tired or moody. Take it slow and prioritize rest.';
    } else if (day >= 6 && day <= 13) {
      return 'Follicular phase – Energy levels are rising! It’s a great time for creativity and socializing.';
    } else if (day >= 14 && day <= 16) {
      return 'Ovulation phase – You may feel confident and energized. Great time for decision-making!';
    } else if (day >= 17 && day <= 28) {
      return 'Luteal phase – You might feel more sensitive. Be kind to yourself and get enough rest.';
    } else {
      return 'Select a day to get mood tips.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mental Health'),
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: beigeColor),
          onPressed: () {
            Navigator.pop(context); // ← to cofnie do poprzedniego ekranu
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Cycle Calendar',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 16),
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _selectedDay ?? DateTime.now(),
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _moodMessage = _getMoodMessage(selectedDay);
                });
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SizedBox(height: 20),
            if (_moodMessage != null)
              Text(
                _moodMessage!,
                style: TextStyle(fontSize: 16, color: primaryColor),
              ),
            SizedBox(height: 30),
            Text(
              'Psychological Chatbot',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: beigeColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Chatbot coming soon...',
                style: TextStyle(color: primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HelpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help'),
        backgroundColor: Color(0xFF2D2A4A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need Help?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2A4A),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'If you need help or have any questions, please don’t hesitate to contact us via the Contact section.',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF2D2A4A),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'We are here to support you with:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D2A4A),
              ),
            ),
            SizedBox(height: 8),
            BulletPoint(text: 'Technical issues related to the app'),
            BulletPoint(text: 'Questions about courses or events'),
            BulletPoint(text: 'Mental health resources'),
            BulletPoint(text: 'General inquiries about Woman In STEM'),
            SizedBox(height: 20),
            Text(
              'Our team strives to respond within 24 hours.\n\nThank you for being part of our community!',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF2D2A4A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BulletPoint extends StatelessWidget {
  final String text;

  BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("•  ",
              style: TextStyle(fontSize: 18, color: Color(0xFF2D2A4A))),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 16, color: Color(0xFF2D2A4A)),
            ),
          ),
        ],
      ),
    );
  }
}

