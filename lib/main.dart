import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aws_s3_upload/aws_s3_upload.dart';
import 'package:aws_s3_upload/enum/acl.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter AWS S3 Upload',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _selectedFile;
  String? _uploadedImageUrl;
  bool _isUploading = false;

  final String region = 'YOUR_AWS_REGION';
  final String bucketName = 'YOUR_BUCKET_NAME';
  final String accessKey = 'YOUR_ACCESS_KEY_ID';
  final String secretKey = 'YOUR_SECRET_ACCESS_KEY';

  // Function to pick image
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
      });
    } else {
      print("No image selected.");
    }
  }

  // Function to upload image to AWS S3
  Future<void> _uploadImageToS3() async {
    if (_selectedFile == null) return;

    setState(() {
      _isUploading = true;
    });

    String fileName = '${DateTime.now().millisecondsSinceEpoch}-${_selectedFile!.path.split('/').last}';

    try {
      final result = await AwsS3.uploadFile(
        accessKey: accessKey,
        secretKey: secretKey,
        file: _selectedFile!,
        bucket: bucketName,
        region: region,
        acl: ACL.public_read,
        key: fileName,
        metadata: {
          'Content-Type': 'image/${_selectedFile!.path.split('.').last}',
        },
      );

      if (result != null) {
        setState(() {
          _uploadedImageUrl = result; // URL of the uploaded image
        });
        print('Upload success: $result');
      } else {
        print('Upload failed');
      }
    } catch (error) {
      print("Upload error: $error");
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AWS S3 Image Upload"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_selectedFile != null)
              Image.file(_selectedFile!, height: 200, width: 200),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text("Select Image"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadImageToS3,
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Upload to S3"),
            ),
            if (_uploadedImageUrl != null) ...[
              const SizedBox(height: 20),
              const Text("Uploaded Image URL:"),
              InkWell(
                onTap: () => print("Image URL: $_uploadedImageUrl"),
                child: Text(
                  _uploadedImageUrl!,
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
