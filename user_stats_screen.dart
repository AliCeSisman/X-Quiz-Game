import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:XQuizGame/turkey_stats_screen.dart';

class UserStatsScreen extends StatelessWidget {
  final String userId;

  const UserStatsScreen({super.key, required this.userId});

  Future<Map<String, dynamic>?> getUserStats() async {
    try {
      final DocumentSnapshot statsSnapshot = await FirebaseFirestore.instance
          .collection('user_stats')
          .doc(userId)
          .get();

      if (statsSnapshot.exists) {
        return statsSnapshot.data() as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('İstatistikler yüklenirken hata oluştu: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı İstatistikleri'),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: getUserStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text(
                'İstatistik bulunamadı!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          }

          final stats = snapshot.data!;
          final totalQuestions = (stats['totalCorrectAnswers'] ?? 0) +
              (stats['totalWrongAnswers'] ?? 0);
          final correctAnswers = stats['totalCorrectAnswers'] ?? 0;
          final wrongAnswers = stats['totalWrongAnswers'] ?? 0;

          // Başarı oranını hesapla
          final successRate = totalQuestions > 0
              ? ((correctAnswers / totalQuestions) * 100).toStringAsFixed(1)
              : '0.0';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık
                const Center(
                  child: Text(
                    'İstatistikleriniz',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),

                // Toplam Puan
                _buildStatCard(
                  title: 'Toplam Puan',
                  value: '${stats['totalPoints']} Puan',
                  color: Colors.green.shade100,
                  textColor: Colors.green.shade700,
                ),
                const SizedBox(height: 10),

                // Toplam Doğru Sayısı
                _buildStatCard(
                  title: 'Toplam Doğru',
                  value: '$correctAnswers Soru',
                  color: Colors.blue.shade100,
                  textColor: Colors.blue.shade700,
                ),
                const SizedBox(height: 10),

                // Toplam Yanlış Sayısı
                _buildStatCard(
                  title: 'Toplam Yanlış',
                  value: '$wrongAnswers Soru',
                  color: Colors.red.shade100,
                  textColor: Colors.red.shade700,
                ),
                const SizedBox(height: 10),

                // Oynanan Oyun Sayısı
                _buildStatCard(
                  title: 'Oynanan Oyun',
                  value: '${stats['gamesPlayed']} Oyun',
                  color: Colors.orange.shade100,
                  textColor: Colors.orange.shade700,
                ),
                const SizedBox(height: 10),

                // Toplam Süre
                _buildStatCard(
                  title: 'Toplam Süre',
                  value: '${stats['totalTime']} saniye',
                  color: Colors.purple.shade100,
                  textColor: Colors.purple.shade700,
                ),
                const SizedBox(height: 10),

                // Başarı Oranı
                _buildStatCard(
                  title: 'Başarı Oranı',
                  value: '%$successRate',
                  color: Colors.teal.shade100,
                  textColor: Colors.teal.shade700,
                ),
                const Spacer(),

                // Türkiye Geneli İstatistikler Butonu
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TurkeyStatsScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Türkiye Geneli İstatistikler',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade400,
            blurRadius: 6.0,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
