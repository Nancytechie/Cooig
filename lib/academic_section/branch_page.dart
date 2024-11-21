//import 'material_upload.dart';
import 'package:cooig_firebase/academic_section/unit_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BranchPage extends StatefulWidget {
  const BranchPage({super.key});

  @override
  State<BranchPage> createState() => _BranchPageState();
}

class _BranchPageState extends State<BranchPage> {
  // Function to navigate to the respective branch page
  void navigateToBranch(String branch) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BranchMaterialPage(branch: branch),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [
            Color(0xFF1C1C1E),
            Color(0xFF000000),
          ],
          radius: 0.0,
          center: Alignment.center,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.black,
          title: Text(
            'Material Hub',
            style: GoogleFonts.ebGaramond(
              textStyle: const TextStyle(
                color: Color(0XFF9752C5), // Contrast with button colors
                fontSize: 30,
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // B.Tech Section
                SectionHeader(
                  title: "B.Tech",
                  description: "Explore study materials for B.Tech branches",
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    for (var branch in [
                      'CSE-AI',
                      'CSE',
                      'IT',
                      'MAE',
                      'ECE',
                      'ECE-AI',
                      'AI-ML',
                      'DMAM'
                    ])
                      AnimatedRoundedRectButton(
                        label: branch,
                        onPressed: () => navigateToBranch(branch),
                      ),
                  ],
                ),
                const SizedBox(height: 40),
                // Management Section
                SectionHeader(
                  title: "Management",
                  description: "Explore study materials Management programs",
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    AnimatedRoundedRectButton(
                      label: "BBA",
                      onPressed: () => navigateToBranch("BBA"),
                    ),
                    AnimatedRoundedRectButton(
                      label: "MBA",
                      onPressed: () => navigateToBranch("MBA"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Section Header Widget
class SectionHeader extends StatelessWidget {
  final String title;
  final String description;

  const SectionHeader({
    required this.title,
    required this.description,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: GoogleFonts.ebGaramond(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Custom Animated Rounded Rectangle Button
class AnimatedRoundedRectButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const AnimatedRoundedRectButton({
    required this.label,
    required this.onPressed,
    Key? key,
  }) : super(key: key);

  @override
  _AnimatedRoundedRectButtonState createState() =>
      _AnimatedRoundedRectButtonState();
}

class _AnimatedRoundedRectButtonState extends State<AnimatedRoundedRectButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: MouseRegion(
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: isHovered ? 160 : 140, // Adjusting size for hover effect
          height: isHovered ? 60 : 50, // Adjusting size for hover effect
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isHovered
                  ? [Color(0XFF9752C5), Colors.deepPurpleAccent]
                  : [Colors.purple, const Color.fromARGB(255, 115, 41, 165)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: isHovered
                ? [
                    BoxShadow(
                      color: Colors.pink.shade200,
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: GoogleFonts.poppins(
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Placeholder for the branch material page

// BranchMaterialPage class
class BranchMaterialPage extends StatelessWidget {
  final String branch;

  const BranchMaterialPage({required this.branch, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Define reusable text styles for better optimization
    TextStyle headingStyle = GoogleFonts.ebGaramond(
      textStyle: const TextStyle(
        color: Color(0XFF9752C5), // Title color
        fontSize: 32,
        fontWeight: FontWeight.w400,
      ),
    );

    // Button text style for better optimization
    TextStyle buttonTextStyle = GoogleFonts.ebGaramond(
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );

    // Determine the number of years based on the branch
    int totalYears = branch == 'MBA'
        ? 2
        : branch == 'BBA'
            ? 3
            : 4;

    // Generate semesters based on years for the branch
    List<List<int>> semestersPerYear = [];
    for (int year = 1; year <= totalYears; year++) {
      List<int> semesters = [];
      // Add semesters dynamically based on the year
      if (year == 1) {
        semesters.add(1);
        semesters.add(2);
      } else if (year == 2) {
        semesters.add(3);
        semesters.add(4);
      } else if (year == 3) {
        semesters.add(5);
        semesters.add(6);
      } else if (year == 4) {
        semesters.add(7);
        semesters.add(8);
      }
      semestersPerYear.add(semesters);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(branch, style: headingStyle),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Loop through each year
                for (var yearIndex = 0;
                    yearIndex < totalYears;
                    yearIndex++) ...[
                  // Year Title with Increased Font Size and Bold
                  Text(
                    "${yearIndex + 1} Year",
                    style: GoogleFonts.ebGaramond(
                      fontSize: 26, // Increased font size for year label
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Wrap to place semester buttons dynamically
                  Wrap(
                    spacing: 20, // Increased gap between buttons
                    runSpacing: 15, // Space between rows of buttons
                    alignment: WrapAlignment.center,
                    children: [
                      for (var semester in semestersPerYear[yearIndex])
                        AnimatedRoundedRectButton(
                          label: 'Sem ${semester}', // Shortened text

                          onPressed: () {
                            // Navigate to respective semester page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SemesterPage(
                                  branch: branch,
                                  year: yearIndex + 1,
                                  semester: semester,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// SemesterPage class for displaying subject details

class SemesterPage extends StatelessWidget {
  final String branch;
  final int year;
  final int semester;

  const SemesterPage({
    required this.branch,
    required this.year,
    required this.semester,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Data for subjects, units, and links for each branch and semester
    Map<String, Map<int, Map<String, List<Map<String, String>>>>> data = {
      'CSE-AI': {
        1: {
          'Math': [
            {'Unit 1': 'https://link-to-unit-1'},
            {'Unit 2': 'https://link-to-unit-2'},
          ],
          'Physics': [
            {'Unit 1': 'https://link-to-physics-unit-1'},
            {'Unit 2': 'https://link-to-physics-unit-2'},
          ],
          'Programming': [
            {'Unit 1': 'https://programming-unit-1'},
          ],
        },
        2: {
          'Data Structures': [
            {'Unit 1': 'https://ds-unit-1'},
            {'Unit 2': 'https://ds-unit-2'},
          ],
          'Algorithms': [
            {'Unit 1': 'https://algorithms-unit-1'},
          ],
        },
        3: {
          'AI Fundamentals': [
            {'Unit 1': 'https://ai-unit-1'},
          ],
          'Mathematics': [
            {'Unit 1': 'https://math-unit-1'},
          ],
        },
        4: {
          'Machine Learning': [
            {'Unit 1': 'https://ml-unit-1'},
          ],
          'Probability and Statistics': [
            {'Unit 1': 'https://stats-unit-1'},
          ],
        },
        // Continue adding subjects for semesters 5-8
      },
      'CSE': {
        1: {
          'Math': [
            {'Unit 1': 'https://link-to-math-1'},
            {'Unit 2': 'https://link-to-math-2'},
          ],
          'Physics': [
            {'Unit 1': 'https://link-to-physics-1'},
            {'Unit 2': 'https://link-to-physics-2'},
          ],
        },
        2: {
          'Data Structures': [
            {'Unit 1': 'https://ds-unit-1'},
            {'Unit 2': 'https://ds-unit-2'},
          ],
          'Computer Networks': [
            {'Unit 1': 'https://cn-unit-1'},
          ],
        },
        // Continue adding subjects for CSE and all other branches for 3-8 semesters
      },
      'IT': {
        1: {
          'Math': [
            {'Unit 1': 'https://math-unit-1'},
            {'Unit 2': 'https://math-unit-2'},
          ],
          'Electronics': [
            {'Unit 1': 'https://electronics-unit-1'},
          ],
        },
        2: {
          'Software Engineering': [
            {'Unit 1': 'https://se-unit-1'},
          ],
          'Operating Systems': [
            {'Unit 1': 'https://os-unit-1'},
          ],
        },
        // Continue adding subjects for IT and other semesters
      },
      'MAE': {
        1: {
          'Engineering Mechanics': [
            {'Unit 1': 'https://eng-mechanics-unit-1'},
          ],
          'Material Science': [
            {'Unit 1': 'https://material-science-unit-1'},
          ],
        },
        2: {
          'Fluid Mechanics': [
            {'Unit 1': 'https://fluid-mechanics-unit-1'},
          ],
          'Thermodynamics': [
            {'Unit 1': 'https://thermodynamics-unit-1'},
          ],
        },
        // Continue adding subjects for MAE and other semesters
      },
      'ECE': {
        1: {
          'Mathematics': [
            {'Unit 1': 'https://math-unit-1'},
          ],
          'Electronics': [
            {'Unit 1': 'https://electronics-unit-1'},
          ],
        },
        2: {
          'Signals and Systems': [
            {'Unit 1': 'https://signals-systems-unit-1'},
          ],
          'Digital Electronics': [
            {'Unit 1': 'https://digital-electronics-unit-1'},
          ],
        },
        // Continue adding subjects for ECE and other semesters
      },
      'ECE-AI': {
        1: {
          'Math': [
            {'Unit 1': 'https://math-unit-1'},
            {'Unit 2': 'https://math-unit-2'},
          ],
          'Physics': [
            {'Unit 1': 'https://physics-unit-1'},
          ],
        },
        2: {
          'AI Fundamentals': [
            {'Unit 1': 'https://ai-fundamentals-unit-1'},
          ],
          'Data Structures': [
            {'Unit 1': 'https://ds-unit-1'},
          ],
        },
        // Continue adding subjects for ECE-AI and other semesters
      },
      'AI-ML': {
        1: {
          'Math': [
            {'Unit 1': 'https://math-unit-1'},
          ],
          'Statistics': [
            {'Unit 1': 'https://stats-unit-1'},
          ],
        },
        2: {
          'Machine Learning': [
            {'Unit 1': 'https://ml-unit-1'},
          ],
          'Deep Learning': [
            {'Unit 1': 'https://dl-unit-1'},
          ],
        },
        // Continue adding subjects for AI-ML and other semesters
      },
      'DMAM': {
        1: {
          'Mathematics': [
            {'Unit 1': 'https://math-unit-1'},
          ],
        },
        2: {
          'Advanced Mathematics': [
            {'Unit 1': 'https://adv-math-unit-1'},
          ],
        },
        // Continue adding subjects for DMAM and other semesters
      },
    };

    // Get subjects for the current branch and semester
    var subjects = data[branch]?[semester] ?? {};
    var isEmpty = subjects.isEmpty;

    return Scaffold(
      appBar: AppBar(
          title: Text('$branch - Year $year, Sem $semester'),
          backgroundColor: Colors.black,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
            textStyle: const TextStyle(
              color: Colors.white, // Title color
              fontSize: 26,
              fontWeight: FontWeight.w500,
            ),
          )),
      backgroundColor: Colors.black,
      body: isEmpty
          ? Center(
              child: Text(
                'No subjects available for $branch in Semester $semester',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    // Display subject containers dynamically
                    for (var subject in subjects.keys) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(
                            24), // Increased padding for better space
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(
                              0.1), // Light grey background with opacity for subtle effect
                          borderRadius:
                              BorderRadius.circular(30), // Rounded corners
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                  0.2), // Soft shadow with black opacity for a more elegant look
                              spreadRadius: 3,
                              blurRadius: 6,
                              offset: Offset(
                                  0, 4), // Slight shadow offset for depth
                            ),
                          ],
                          border: Border.all(
                            width: 4, // Thicker border for better definition
                            color: Colors.grey.withOpacity(
                                0.5), // Grey border with opacity for a refined look
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              subject,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(255, 132, 92,
                                    241), // Text color set to white
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Display units for each subject
                            for (var unit in subjects[subject]!) ...[
                              for (var unitName in unit.keys) ...[
                                GestureDetector(
                                  onTap: () {
                                    // Navigate to the Unit page on click
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => UnitPage(
                                          branch: branch,
                                          year: semester,
                                          subject: subject,
                                          unitName: unitName,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 5),
                                    child: Text(
                                      unitName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.white.withOpacity(
                                            0.8), // Text color white with slight opacity
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
