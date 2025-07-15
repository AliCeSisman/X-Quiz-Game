import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final CollectionReference userQuestions =
      FirebaseFirestore.instance.collection('user_questions');
  final CollectionReference questions =
      FirebaseFirestore.instance.collection('questions');

  /// Soruyu Onayla: Soru "questions" koleksiyonuna taşınır ve user_questions'tan silinir
  Future<void> approveQuestion(DocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final targetCollection = data['targetCollection'] ?? 'questions';

      // Hedef koleksiyona eklemeden önce geçerli veri olup olmadığını kontrol et
      if (data['question'] != null && data['options'] != null) {
        // Soruyu ilgili koleksiyona ekle
        await FirebaseFirestore.instance.collection(targetCollection).add({
          ...data, // Mevcut tüm veriyi kopyala
          'approvedAt': FieldValue.serverTimestamp(), // Onay zamanını ekle
        });

        // user_questions'tan sil
        await FirebaseFirestore.instance
            .collection('user_questions')
            .doc(doc.id)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Soru onaylandı ve ilgili koleksiyona taşındı!')),
        );
      } else {
        throw Exception("Eksik veya geçersiz veri");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  /// Soruyu Sil: Kullanıcıdan onay alarak user_questions'tan siler
  Future<void> deleteQuestion(String docId) async {
    try {
      final confirm = await _showConfirmationDialog(
        title: 'Sil',
        content: 'Bu soruyu silmek istediğinizden emin misiniz?',
      );
      if (!confirm) return;

      await userQuestions.doc(docId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Soru başarıyla silindi!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  /// Detayları Gösteren Dialog
  void _showQuestionDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Soru Detayları'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Soru: ${data['question'] ?? 'Belirtilmemiş'}'),
              const SizedBox(height: 10),
              Text('Kategori: ${data['category'] ?? 'Belirtilmemiş'}'),
              const SizedBox(height: 10),
              const Text('Şıklar:'),
              ..._convertToListOfStrings(data['options']).map(
                (option) => Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                  child: Text('- $option'),
                ),
              ),
              const SizedBox(height: 10),
              Text('Doğru Cevap: ${data['correctAnswer'] ?? 'Belirtilmemiş'}'),
              const SizedBox(height: 10),
              const Text('50:50 Joker Şıkları:'),
              ..._convertToListOfStrings(data['joker50']).map(
                (joker) => Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                  child: Text('- $joker'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  /// Güvenli şekilde listeyi String'lere dönüştür
  List<String> _convertToListOfStrings(dynamic input) {
    if (input == null) return [];
    if (input is List) {
      return input.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Onay Dialog'u
  Future<bool> _showConfirmationDialog({
    required String title,
    required String content,
  }) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Hayır'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Evet'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Onay Bekleyen Sorular'),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder(
        stream: userQuestions.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Onay bekleyen soru bulunmuyor.'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: const Icon(Icons.question_mark, color: Colors.blue),
                  title: Text(data['question'] ?? 'Soru belirtilmemiş',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle:
                      Text('Kategori: ${data['category'] ?? 'Bilinmiyor'}'),
                  onTap: () => _showQuestionDetails(data), // Detayları göster
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => approveQuestion(doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteQuestion(doc.id),
                      ),
                    ],
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
