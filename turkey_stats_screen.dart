import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TurkeyStatsScreen extends StatelessWidget {
  const TurkeyStatsScreen({super.key});

  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('user_stats')
          .orderBy('totalPoints', descending: true)
          .get();

      final userStats = querySnapshot.docs.map((doc) => doc.data()).toList();

      final List userIds = userStats.map((stat) => stat['userID']).toList();

      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: userIds)
          .get();

      final Map<String, String> userNames = {
        for (var doc in usersSnapshot.docs)
          doc.id: doc.data()['kullaniciAdi'] ?? 'Bilinmeyen Kullanıcı'
      };

      return userStats.map((stat) {
        final userId = stat['userID'];
        final totalCorrect = stat['totalCorrectAnswers'] ?? 0;
        final totalWrong = stat['totalWrongAnswers'] ?? 0;
        final totalQuestions = totalCorrect + totalWrong;
        final successRate = totalQuestions > 0
            ? ((totalCorrect / totalQuestions) * 100).toStringAsFixed(1)
            : '0.0';

        return {
          'username': userNames[userId] ?? 'Bilinmeyen Kullanıcı',
          'totalPoints': stat['totalPoints'] ?? 0,
          'totalQuestions': totalQuestions,
          'correctAnswers': totalCorrect,
          'wrongAnswers': totalWrong,
          'successRate': successRate,
        };
      }).toList();
    } catch (e) {
      debugPrint('Hata: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Türkiye Geneli İstatistikler'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getLeaderboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Hiç veri bulunamadı.'));
          }

          final leaderboard = snapshot.data!;

          return ListView.builder(
            itemCount: leaderboard.length,
            itemBuilder: (context, index) {
              final user = leaderboard[index];
              final rank = index + 1;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: rank == 1
                        ? Colors.amber
                        : rank == 2
                            ? Colors.grey
                            : rank == 3
                                ? Colors.brown
                                : Colors.blue.shade100,
                    child: Text(
                      '$rank',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  title: Text(
                    user['username'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    'Doğru: ${user['correctAnswers']} | Yanlış: ${user['wrongAnswers']} | Başarı: %${user['successRate']}',
                  ),
                  trailing: Text(
                    '${user['totalPoints']} Puan',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
