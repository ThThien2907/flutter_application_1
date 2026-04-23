import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const OcrScreen(),
    );
  }
}

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  String _recognizedText = "Chưa nhận diện văn bản";

  Future<void> _pickAndScanImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    // final preprocessedFile = await _preprocessImage(File(pickedFile.path));

    _imageFile = File(pickedFile.path);

    final inputImage = InputImage.fromFile(_imageFile!);

    final textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );

    final RecognizedText result = await textRecognizer.processImage(inputImage);

    String sortedText = sortTextByCoordinates(result);

    Map<String, String> data = DataExtractor.extract(sortedText);

    setState(() {
      _recognizedText = sortedText;
      print("Full Text:\n$sortedText");
    });

    textRecognizer.close();
  }

  Future<void> _takePhoto() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    final inputImage = InputImage.fromFile(File(pickedFile!.path));

    final textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );

    final RecognizedText result = await textRecognizer.processImage(inputImage);

    String sortedText = sortTextByCoordinates(result);

    setState(() {
      _recognizedText = sortedText;
    });

    setState(() {
      _recognizedText = sortedText;

      _imageFile = File(pickedFile.path);
    });
  }

  Future<File> _preprocessImage(File file) async {
    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    // Convert sang grayscale
    image = img.grayscale(image!);

    // Tăng contrast
    image = img.adjustColor(image, contrast: 1.5);

    final newPath = file.path.replaceFirst('.jpg', '_processed.jpg');
    return File(newPath)..writeAsBytesSync(img.encodeJpg(image));
  }

  String sortTextByCoordinates(RecognizedText result) {
    // 1. Thu thập tất cả các TextLine vào một danh sách phẳng
    List<TextLine> allLines = [];
    for (TextBlock block in result.blocks) {
      allLines.addAll(block.lines);
    }

    // 2. Sắp xếp theo trục Y (từ trên xuống dưới)
    // Nếu 2 dòng có độ cao gần bằng nhau (sai số 10px), thì dòng nào bên trái hơn sẽ đứng trước
    allLines.sort((a, b) {
      int yDiff = (a.boundingBox.top - b.boundingBox.top).abs().toInt();
      if (yDiff < 15) {
        // Ngưỡng 15 pixel để coi là cùng 1 dòng ngang
        return a.boundingBox.left.compareTo(b.boundingBox.left);
      }
      return a.boundingBox.top.compareTo(b.boundingBox.top);
    });

    // 3. Nối các dòng đã sắp xếp thành chuỗi văn bản
    StringBuffer buffer = StringBuffer();
    for (var line in allLines) {
      buffer.writeln(line.text);
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("OCR với Flutter"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          _imageFile != null
              ? Image.file(
                  _imageFile!,
                  width: 300,
                  height: 300,
                  fit: BoxFit.cover,
                )
              : const Text("Chưa có ảnh"),

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text("Chụp ảnh"),
              ),
              const SizedBox(width: 20),
              ElevatedButton.icon(
                onPressed: _pickAndScanImage,
                icon: const Icon(Icons.image),
                label: const Text("Chọn ảnh để nhận diện"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Hiển thị kết quả nhận diện
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(_recognizedText, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: () {
                          Map<String, String> data =
                              DataExtractor.extract(_recognizedText);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    ExtractDataScreen(arguments: data)),
                          );
                        },
                        child: const Text('Trích xuất dữ liệu')),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExtractDataScreen extends StatefulWidget {
  final Map<String, String> arguments;

  const ExtractDataScreen({super.key, required this.arguments});

  @override
  State<ExtractDataScreen> createState() => _ExtractDataScreenState();
}

class _ExtractDataScreenState extends State<ExtractDataScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trích xuất dữ liệu"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              initialValue: widget.arguments['name'],
              decoration: const InputDecoration(labelText: 'Tên'),
            ),
            TextFormField(
              initialValue: widget.arguments['address'],
              decoration: const InputDecoration(labelText: 'Địa chỉ'),
            ),
            TextFormField(
              initialValue: widget.arguments['phone'],
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
            )
          ],
        ),
      ),
    );
  }
}

class OcrKeywords {
  static const List<String> nameKeywords = [
    "họ tên",
    "họ ten",
    "ho tên",
    "ho ten",
    "họ và tên",
    "ho và tên",
    "họ va tên",
    "họ và ten",
    "ho va ten",
    "tên bệnh nhân",
    "bệnh nhân",
    "ten benh nhan",
    "benh nhan",
    "tên khách hàng"
  ];
  static const List<String> addressKeywords = [
    "địa chỉ",
    "đia chi",
    "địa chi",
    "dia chỉ",
    "dịa chi",
    "dịa chỉ",
    "dia chi",
    "dja chi",
    "dja chỉ",
    "đ/c",
    "dc",
    "nơi ở"
  ];

  static const List<String> phoneKeywords = [
    "sđt",
    "sdt",
    "số điện thoại",
    "số điện thoai",
    "số dien thoại",
    "so điện thoại",
    "so điện thoại",
    "điện thoại",
    "điện thoại",
    "dien thoai",
    "phone"
  ];

  // Danh sách đen để tránh lấy nhầm thông tin rác
  static const List<String> blacklist = [
    "bác sĩ",
    "bs",
    "lời dặn",
    "tái khám",
    "nhớ mang theo",
    "giấy chuyển viện"
  ];
}

class DataExtractor {
  static Map<String, String> extract(String fullText) {
    List<String> lines = fullText.split('\n');
    String name = "Chưa xác định";
    String address = "Chưa xác định";
    String phone = "Chưa xác định";

    bool foundName = false;
    bool foundAddress = false;
    bool foundPhone = false;

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty) continue;
      String lower = line.toLowerCase();

      // --- 1. LỌC TÊN ---
      if (!foundName &&
          OcrKeywords.nameKeywords.any((k) => lower.contains(k))) {
        String potentialName = _getValue(lines, i);
        if (_isValidInfo(potentialName, isName: true)) {
          name = potentialName;
          foundName = true;
        }
      }

      // --- 2. LỌC ĐỊA CHỈ ---
      if (!foundAddress &&
          OcrKeywords.addressKeywords.any((k) => lower.contains(k))) {
        String potentialAddress = _getValue(lines, i);
        if (_isValidInfo(potentialAddress)) {
          address = potentialAddress;
          foundAddress = true;
        }
      }

      // --- 3. LỌC SỐ ĐIỆN THOẠI ---
      // Ưu tiên dòng có chứa keyword điện thoại trước
      if (!foundPhone) {
        final phoneRegex = RegExp(r'(0|\+84)[3|5|7|8|9][0-9\.\-\s]{8,12}');
        if (phoneRegex.hasMatch(line)) {
          String rawPhone = phoneRegex.stringMatch(line)!;
          // Làm sạch số: Xóa dấu chấm, khoảng trắng, gạch ngang
          phone = rawPhone.replaceAll(RegExp(r'[\.\-\s]'), '');
          if (phone.length >= 10) foundPhone = true;
        }
      }
    }

    return {"name": name, "address": address, "phone": phone};
  }

  // Lấy giá trị sau dấu : hoặc ở dòng kế tiếp
  static String _getValue(List<String> lines, int index) {
    String currentLine = lines[index];
    if (currentLine.contains(':')) {
      String afterColon = currentLine.split(':').last.trim();
      if (afterColon.isNotEmpty) return afterColon;
    }
    // Nếu dòng hiện tại chỉ chứa keyword, lấy dòng ngay phía dưới
    if (index + 1 < lines.length) {
      return lines[index + 1].trim();
    }
    return "";
  }

  // Kiểm tra xem dữ liệu có phải là "rác" không
  static bool _isValidInfo(String info, {bool isName = false}) {
    if (info.isEmpty) return false;
    String low = info.toLowerCase();

    // Nếu chứa từ khóa trong blacklist thì loại bỏ
    if (OcrKeywords.blacklist.any((b) => low.contains(b))) return false;

    // Tên thường không quá dài (đề phòng lấy nhầm nguyên câu dặn dò)
    if (isName && info.length > 30) return false;

    return true;
  }
}
