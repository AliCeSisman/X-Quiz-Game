import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddQuestionScreen extends StatefulWidget {
  const AddQuestionScreen({super.key});

  @override
  _AddQuestionScreenState createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends State<AddQuestionScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form alanlarının kontrolcülerini oluşturuyoruz
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionsControllers =
      List.generate(5, (_) => TextEditingController());
  final TextEditingController _correctAnswerController =
      TextEditingController();
  final TextEditingController _joker50Controller1 = TextEditingController();
  final TextEditingController _joker50Controller2 = TextEditingController();
  final TextEditingController _joker50Controller3 = TextEditingController();

  // Kategori listesi ve seçilen kategori
  final List<String> categories = [
    'Tarih',
    'Coğrafya',
    'Bilgisayar Bilimleri',
    'Bilim ',
    'Sanat',
    'Genel Kültür',
    'Spor',
  ];
  String? _selectedCategory;

  // Sorunun kaydedileceği koleksiyon
  final List<String> collections = ['Kolay Sorular', 'Zor Sorular'];
  String selectedCollection = 'Kolay Sorular'; // Varsayılan koleksiyon

  // Firestore'a veri ekleme fonksiyonu
  Future<void> _addQuestionToFirestore() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Firestore'a ekleme işlemi (her zaman user_questions'a ekle)
        await FirebaseFirestore.instance.collection('user_questions').add({
          'question': _questionController.text,
          'options':
              _optionsControllers.map((controller) => controller.text).toList(),
          'correctAnswer': _correctAnswerController.text,
          'joker50': [
            _joker50Controller1.text,
            _joker50Controller2.text,
            _joker50Controller3.text
          ],
          'category': _selectedCategory,
          'timeLimit': 30,
          'points': 0,
          'targetCollection': selectedCollection == 'Kolay Sorular'
              ? 'questions'
              : 'hard_questions', // Kolay veya zor sorular
        });

        // Başarılı işlem sonrası kullanıcıya bildirim ve alanların sıfırlanması
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Soru başarıyla eklendi ve onay bekliyor!'),
            backgroundColor: Colors.green,
          ),
        );
        _clearForm();
      } catch (error) {
        // Hata durumu
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: Soru eklenemedi! Hata: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearForm() {
    _questionController.clear();
    for (var controller in _optionsControllers) {
      controller.clear();
    }
    _correctAnswerController.clear();
    _joker50Controller1.clear();
    _joker50Controller2.clear();
    _joker50Controller3.clear();
    setState(() {
      _selectedCategory = null; // Seçili kategori sıfırlanır
      selectedCollection = 'Kolay Sorular'; // Koleksiyon seçimi sıfırlanır
    });
  }

  Widget _buildTextField(
      {required String label,
      required TextEditingController controller,
      String? hintText,
      bool isRequired = true}) {
    return Card(
      elevation: 3,
      shadowColor: Colors.blueGrey.withOpacity(0.3),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          labelText: label,
          hintText: hintText,
          border: InputBorder.none,
        ),
        validator: (value) =>
            isRequired && value!.isEmpty ? '$label boş bırakılamaz' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soru Ekleme Ekranı'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Center(
                  child: Text(
                    'Yeni Soru Ekle',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Soru alanı
                _buildTextField(
                  label: 'Soru',
                  controller: _questionController,
                  hintText: 'Sorunuzu buraya yazın',
                ),
                const Divider(),
                // Şıklar
                const Text(
                  'Şıklar:',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey),
                ),
                ..._optionsControllers.asMap().entries.map((entry) {
                  final index = entry.key;
                  return _buildTextField(
                    label: 'Şık ${index + 1}',
                    controller: entry.value,
                  );
                }),
                const Divider(),
                // Doğru Cevap
                _buildTextField(
                  label: 'Doğru Cevap',
                  controller: _correctAnswerController,
                  hintText: 'Doğru şıkkı yazın',
                ),
                const Divider(),
                // Joker 50:50 Alanları
                const Text(
                  'Joker 50:50 Kalacak Şıklar:',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey),
                ),
                _buildTextField(
                  label: 'Kalacak Şık 1',
                  controller: _joker50Controller1,
                ),
                _buildTextField(
                  label: 'Kalacak Şık 2',
                  controller: _joker50Controller2,
                ),
                _buildTextField(
                  label: 'Kalacak Şık 3',
                  controller: _joker50Controller3,
                ),
                const Divider(),
                // Kategori Seçimi
                Card(
                  elevation: 3,
                  shadowColor: Colors.blueGrey.withOpacity(0.3),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        border: InputBorder.none,
                      ),
                      value: _selectedCategory,
                      items: categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Lütfen bir kategori seçin' : null,
                    ),
                  ),
                ),
                const Divider(),
                // Koleksiyon Seçimi
                Card(
                  elevation: 3,
                  shadowColor: Colors.blueGrey.withOpacity(0.3),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Soru Türü',
                        border: InputBorder.none,
                      ),
                      value: selectedCollection,
                      items: collections.map((collection) {
                        return DropdownMenuItem<String>(
                          value: collection,
                          child: Text(collection),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCollection = value!;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Lütfen bir soru türü seçin' : null,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Kaydet Butonu
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _addQuestionToFirestore,
                      icon: const Icon(Icons.save),
                      label: const Text(
                        'Soruyu Kaydet',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Kontrolcüleri temizle
    _questionController.dispose();
    for (var controller in _optionsControllers) {
      controller.dispose();
    }
    _correctAnswerController.dispose();
    _joker50Controller1.dispose();
    _joker50Controller2.dispose();
    _joker50Controller3.dispose();
    super.dispose();
  }
}
