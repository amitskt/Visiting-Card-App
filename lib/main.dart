import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

void main() {
  runApp(const VisitingCardApp());
}

class VisitingCardApp extends StatelessWidget {
  const VisitingCardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Visiting Card OCR',
      theme: ThemeData(primarySwatch: Colors.green),
      debugShowCheckedModeBanner: false,
      home: const VisitingCardHome(),
    );
  }
}

class VisitingCardHome extends HookWidget {
  const VisitingCardHome({super.key});

  @override
  Widget build(BuildContext context) {
    final picker = ImagePicker();
    final pickedImage = useState<File?>(null);
    final nameController = useTextEditingController();
    final emailController = useTextEditingController();
    final phoneController = useTextEditingController();
    final isLoading = useState(false);

    // ✅ Convert HEIC/HEIF/TIFF/RAW → JPG using flutter_image_compress
    Future<File> convertToJpg(File file) async {
      try {
        final targetPath = file.path.replaceAll(RegExp(r'\.\w+$'), '.jpg');

        final result = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          targetPath,
          format: CompressFormat.jpeg,
          quality: 95,
        );

        if (result == null) {
          throw Exception("HEIC conversion failed");
        }

        return File(result.path);
      } catch (e) {
        throw Exception("Conversion failed: $e");
      }
    }

    Future<void> pickImage(ImageSource source) async {
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        File file = File(pickedFile.path);

        // Check file extension
        final ext = file.path.split('.').last.toLowerCase();
        if (["heic", "heif", "tiff", "raw"].contains(ext)) {
          try {
            file = await convertToJpg(file);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("HEIC conversion failed: $e")),
              );
            }
            return;
          }
        }

        pickedImage.value = file;
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No image selected.")),
          );
        }
      }
    }

    Future<void> uploadImage() async {
      if (pickedImage.value == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select or capture an image.")),
        );
        return;
      }

      isLoading.value = true;

      try {
        var request = http.MultipartRequest(
          "POST",
          Uri.parse("http://206.189.140.34:5001/extract"),
        );
        request.files.add(
          await http.MultipartFile.fromPath("file", pickedImage.value!.path),
        );

        var response = await request.send();
        final res = await http.Response.fromStream(response);

        if (!context.mounted) return;

        if (response.statusCode == 200) {
          final data = jsonDecode(res.body);

          nameController.text =
          (data["name"] == null || data["name"] == "Not Found")
              ? ""
              : data["name"];
          emailController.text =
          (data["email"] == null || data["email"] == "Not Found")
              ? ""
              : data["email"];
          phoneController.text =
          (data["phone"] == null || data["phone"] == "Not Found")
              ? ""
              : data["phone"];
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${res.body}")),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Visiting Card OCR"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              pickedImage.value != null
                  ? Image.file(pickedImage.value!, height: 200, fit: BoxFit.cover)
                  : Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[300],
                child: const Icon(Icons.image, size: 100),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: () => pickImage(ImageSource.camera),
                    label: const Text("Camera"),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.photo),
                    onPressed: () => pickImage(ImageSource.gallery),
                    label: const Text("Gallery"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: "Phone",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: uploadImage,
                    icon: const Icon(Icons.upload),
                    label: isLoading.value
                        ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text("Extract Details"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      nameController.clear();
                      emailController.clear();
                      phoneController.clear();
                      pickedImage.value = null;
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text("Clear"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
