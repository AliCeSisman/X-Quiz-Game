import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'game_statistics_screen.dart';

class EasyModeQuizScreen extends StatefulWidget {
  final String userId;

  const EasyModeQuizScreen({super.key, required this.userId});

  @override
  _EasyModeQuizScreenState createState() => _EasyModeQuizScreenState();
}

class _EasyModeQuizScreenState extends State<EasyModeQuizScreen> {
  List<Map<String, dynamic>> questions = [];
  int currentIndex = 0;
  int totalPoints = 0;
  int remainingTime = 30;
  int totalTimeSpent = 0;
  Timer? timer;

  int correctCount = 0;
  int wrongCount = 0;
  int skippedCount = 0;
  Map<String, int> wrongCategories = {};

  String? feedbackMessage;
  Color feedbackColor = Colors.transparent;

  bool joker50 = true; // 50:50 jokeri
  bool doubleAnswer = true; // Çift cevap jokeri
  bool exactAnswer = true; // Kesin cevap jokeri

  bool doubleAnswerActive = false; // Çift cevap hakkı aktif mi?
  int doubleAnswerAttempts = 2; // Çift cevap jokeri için kalan hak

  bool gameOver = false; // Oyun bitti mi?

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('questions').get();

      final shuffledQuestions =
          querySnapshot.docs.map((doc) => doc.data()).toList()..shuffle();
      questions = shuffledQuestions.take(10).toList();

      startTimer();
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sorular yüklenirken bir hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> updateUserStats() async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('user_stats')
          .doc(widget.userId); // Kullanıcıya özel döküman

      await docRef.set({
        'userID': widget.userId,
        'totalPoints': FieldValue.increment(totalPoints),
        'totalCorrectAnswers': FieldValue.increment(correctCount),
        'totalWrongAnswers': FieldValue.increment(wrongCount),
        'skippedQuestions': FieldValue.increment(skippedCount),
        'totalTime': FieldValue.increment(totalTimeSpent),
        'gamesPlayed': FieldValue.increment(1),
        'lastGameDate': FieldValue.serverTimestamp(),
        'jokerUsage': {
          'joker50': !joker50,
          'doubleAnswer': !doubleAnswer,
          'exactAnswer': !exactAnswer,
        }
      }, SetOptions(merge: true));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Veritabanına kaydedilirken bir hata oluştu: $e')),
        );
      }
    }
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (remainingTime > 0) {
            remainingTime--;
            totalTimeSpent++;
          } else {
            nextQuestion(false);
          }
        });
      }
    });
  }

  Map<String, int> _calculateWrongCategoryCounts() {
    Map<String, int> categoryCounts = {};
    for (var category in wrongCategories.keys) {
      categoryCounts[category] = wrongCategories[category]!;
    }
    return categoryCounts;
  }

  void nextQuestion(bool answeredCorrectly) {
    timer?.cancel();

    if (doubleAnswerActive) {
      if (!answeredCorrectly) {
        doubleAnswerAttempts--;
        if (doubleAnswerAttempts > 0) {
          setState(() {
            feedbackMessage = "Yanlış, $doubleAnswerAttempts hakkınız kaldı!";
            feedbackColor = Colors.orange;
          });
          return;
        } else {
          setState(() {
            doubleAnswerActive = false;
            doubleAnswer = false;
            feedbackMessage = "Yanlış! Çift cevap jokeriniz bitti.";
            feedbackColor = Colors.red;
          });
        }
      } else {
        setState(() {
          correctCount++;
          totalPoints += 3;
          doubleAnswerActive = false;
          feedbackMessage = "Doğru! Çift cevap jokerini kullandınız.";
          feedbackColor = Colors.green;
        });
        moveToNextQuestion();
        return;
      }
    }

    setState(() {
      if (answeredCorrectly) {
        correctCount++;
        totalPoints += 3;
        feedbackMessage = "Doğru!";
        feedbackColor = Colors.green;
      } else {
        wrongCount++;
        totalPoints -= 2;
        feedbackMessage = "Yanlış!";
        feedbackColor = Colors.red;

        final wrongCategory = questions[currentIndex]['category'];

        // null veya boş kategorileri eklememek için kontrol
        if (wrongCategory != null &&
            wrongCategory is String &&
            wrongCategory.trim().isNotEmpty) {
          wrongCategories.update(
            wrongCategory,
            (count) => count + 1, // Kategori zaten varsa sayacı 1 artır
            ifAbsent: () => 1, // Kategori ilk defa ekleniyorsa 1 olarak başlat
          );
        }
      }
    });

    moveToNextQuestion();
  }

  void moveToNextQuestion() async {
    Future.delayed(const Duration(seconds: 1), () async {
      if (currentIndex < questions.length - 1) {
        if (mounted) {
          setState(() {
            currentIndex++;
            remainingTime = questions[currentIndex]['timeLimit'] ?? 30;
            feedbackMessage = null;
            feedbackColor = Colors.transparent;
          });
          startTimer();
        }
      } else {
        timer?.cancel();
        await updateUserStats();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GameStatisticsScreen(
                correctCount: correctCount,
                wrongCount: wrongCount,
                skippedCount: skippedCount,
                totalTimeSpent: totalTimeSpent,
                totalPoints: totalPoints,
                wrongCategories: _calculateWrongCategoryCounts(),
              ),
            ),
          );
        }
      }
    });
  }

  void skipQuestion() {
    timer?.cancel();
    setState(() {
      skippedCount++;
      feedbackMessage = "Soruyu atladınız!";
      feedbackColor = Colors.grey;
    });

    moveToNextQuestion();
  }

  void use50Joker() {
    if (joker50) {
      joker50 = false;
      final jokerOptions = questions[currentIndex]['joker50'] ?? [];
      setState(() {
        questions[currentIndex]['options'] = jokerOptions;
        feedbackMessage = "50:50 Jokerini kullandınız!";
        feedbackColor = Colors.blue;
      });
    } else {
      setState(() {
        feedbackMessage = "50:50 Joker hakkınız bitti!";
        feedbackColor = Colors.red;
      });
    }
  }

  void useExactAnswer() {
    if (exactAnswer) {
      exactAnswer = false;
      final correctAnswer =
          questions[currentIndex]['correctAnswer'] ?? "Bilinmiyor";
      setState(() {
        feedbackMessage = "Kesin Cevap Jokeri: $correctAnswer";
        feedbackColor = Colors.blue;
      });
    } else {
      setState(() {
        feedbackMessage = "Kesin Cevap Joker hakkınız bitti!";
        feedbackColor = Colors.red;
      });
    }
  }

  void activateDoubleAnswer() {
    if (doubleAnswer) {
      setState(() {
        doubleAnswerActive = true;
        doubleAnswerAttempts = 2;
        doubleAnswer = false;
        feedbackMessage = "Çift cevap jokeri aktif: 2 hakkınız var!";
        feedbackColor = Colors.orange;
      });
    } else {
      setState(() {
        feedbackMessage = "Çift Cevap Joker hakkınız bitti!";
        feedbackColor = Colors.red;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Yükleniyor...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (gameOver) {
      return Scaffold(
        appBar: AppBar(title: const Text('Oyun Bitti')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Tebrikler! Toplam Puanınız: $totalPoints',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Ana Menüye Dön'),
              ),
            ],
          ),
        ),
      );
    }

    final question = questions[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Soru ${currentIndex + 1}'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Joker Butonları Üstte
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (joker50) _buildJokerButton('50:50', use50Joker),
                if (doubleAnswer) _buildJokerButton('2x', activateDoubleAnswer),
                if (exactAnswer) _buildJokerButton('1', useExactAnswer),
              ],
            ),

            const SizedBox(height: 60),

            // Zaman Gösterimi
            Center(
              child: CircleAvatar(
                radius: 75,
                backgroundColor: Colors.lightBlueAccent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Toplam Süre',
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                    Text(
                      '$remainingTime',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 60), // Boşluk eklendi

            // Soru Gösterimi
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                question['question'] ?? 'Soru yüklenemedi',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20), // Boşluk eklendi

            // Cevap Seçenekleri
            Wrap(
              spacing: 20,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: question['options'].map<Widget>((option) {
                return SizedBox(
                  width: MediaQuery.of(context).size.width *
                      0.42, // Genişlik oranı
                  height: 60, // Tüm butonlara aynı yükseklik
                  child: ElevatedButton(
                    onPressed: () {
                      nextQuestion(option == question['correctAnswer']);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      option.toString(),
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20), // Boşluk eklendi

            // Soru Atla Butonu
            Center(
              child: ElevatedButton(
                onPressed: skipQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Soru Atla',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            // Geri Bildirim Mesajı
            if (feedbackMessage != null)
              Text(
                feedbackMessage!,
                style: TextStyle(
                  fontSize: 18,
                  color: feedbackColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildJokerButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.greenAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, color: Colors.black),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
