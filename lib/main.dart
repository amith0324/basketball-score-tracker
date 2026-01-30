import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const BasketballScoreApp());
}

class BasketballScoreApp extends StatelessWidget {
  const BasketballScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ScorePage(),
    );
  }
}

class ScorePage extends StatefulWidget {
  const ScorePage({super.key});

  @override
  State<ScorePage> createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage> {
  // SCORES
  int teamAScore = 0;
  int teamBScore = 0;

  // FOULS
  int teamAFouls = 0;
  int teamBFouls = 0;

  // TIMER
  int seconds = 0;
  Timer? timer;
  bool running = false;

  // QUARTERS
  int currentQuarter = 1;
  final int maxQuarters = 4;

  // QUARTER SCORES
  final Map<int, Map<String, int>> quarterScores = {
    1: {'A': 0, 'B': 0},
    2: {'A': 0, 'B': 0},
    3: {'A': 0, 'B': 0},
    4: {'A': 0, 'B': 0},
  };

  // ---------------- SOUND ----------------
  void playScoreSound() {
    SystemSound.play(SystemSoundType.click);
  }

  // ---------------- TIMER ----------------
  void startTimer() {
    if (timer != null) return;
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => seconds++);
    });
    setState(() => running = true);
  }

  void pauseTimer() {
    timer?.cancel();
    timer = null;
    setState(() => running = false);
  }

  void resetTimer() {
    timer?.cancel();
    timer = null;
    setState(() {
      seconds = 0;
      running = false;
    });
  }

  String formatTime() {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  // ---------------- GAME LOGIC ----------------
  void nextQuarter() {
    // Save quarter score
    quarterScores[currentQuarter]!['A'] = teamAScore;
    quarterScores[currentQuarter]!['B'] = teamBScore;

    if (currentQuarter < maxQuarters) {
      setState(() {
        currentQuarter++;
        teamAFouls = 0;
        teamBFouls = 0;
        resetTimer();
      });
    } else {
      showQuarterSummary();
    }
  }

  void showQuarterSummary() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("📊 Match Summary"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (i) {
            int q = i + 1;
            return Text(
              "Q$q  →  Team A: ${quarterScores[q]!['A']}  |  Team B: ${quarterScores[q]!['B']}",
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              resetMatch();
            },
            child: const Text("New Match"),
          ),
        ],
      ),
    );
  }

  void resetMatch() {
    timer?.cancel();
    timer = null;
    setState(() {
      teamAScore = 0;
      teamBScore = 0;
      teamAFouls = 0;
      teamBFouls = 0;
      seconds = 0;
      running = false;
      currentQuarter = 1;
      for (int i = 1; i <= 4; i++) {
        quarterScores[i]!['A'] = 0;
        quarterScores[i]!['B'] = 0;
      }
    });
  }

  String getLeaderText() {
    if (teamAScore > teamBScore) return "🏀 Team A is Leading";
    if (teamBScore > teamAScore) return "🏀 Team B is Leading";
    return "🤝 Match Tied";
  }

  // ---------------- UI ----------------
  Widget scoreButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: 100,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0A1D37),
        ),
        onPressed: onTap,
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget foulButton(VoidCallback onTap) {
    return IconButton(
      icon: const Icon(Icons.warning, color: Colors.orange),
      onPressed: onTap,
    );
  }

  Widget teamCard(String name, int score, int fouls, VoidCallback add1,
      VoidCallback add2, VoidCallback add3, VoidCallback addFoul) {
    bool isLeading = (name == 'Team A' && teamAScore > teamBScore) ||
        (name == 'Team B' && teamBScore > teamAScore);

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(name,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A1D37))),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                '$score',
                key: ValueKey(score),
                style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: isLeading ? Colors.green : const Color(0xFF0A1D37),
                ),
              ),
            ),
            Text("Fouls: $fouls",
                style: const TextStyle(color: Colors.orange)),
            foulButton(addFoul),
            const SizedBox(height: 8),
            scoreButton('+1', add1),
            scoreButton('+2', add2),
            scoreButton('+3', add3),
          ],
        ),
      ),
    );
  }

  // ---------------- BUILD ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1D37),
        title: Text(
          'Basketball Scoreboard 🏀  |  Q$currentQuarter',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // TIMER
            Card(
              child: Column(
                children: [
                  Text(formatTime(),
                      style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A1D37))),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                          onPressed: running ? null : startTimer,
                          child: const Text("Start")),
                      ElevatedButton(
                          onPressed: running ? pauseTimer : null,
                          child: const Text("Pause")),
                      ElevatedButton(
                          onPressed: nextQuarter,
                          child: const Text("Next Q")),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 10),
            Text(getLeaderText(),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            const SizedBox(height: 20),

            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  teamCard(
                    'Team A',
                    teamAScore,
                    teamAFouls,
                    () {
                      setState(() => teamAScore++);
                      playScoreSound();
                    },
                    () {
                      setState(() => teamAScore += 2);
                      playScoreSound();
                    },
                    () {
                      setState(() => teamAScore += 3);
                      playScoreSound();
                    },
                    () => setState(() => teamAFouls++),
                  ),
                  teamCard(
                    'Team B',
                    teamBScore,
                    teamBFouls,
                    () {
                      setState(() => teamBScore++);
                      playScoreSound();
                    },
                    () {
                      setState(() => teamBScore += 2);
                      playScoreSound();
                    },
                    () {
                      setState(() => teamBScore += 3);
                      playScoreSound();
                    },
                    () => setState(() => teamBFouls++),
                  ),
                ],
              ),
            ),

            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: resetMatch,
              child: const Text("Reset Match",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
