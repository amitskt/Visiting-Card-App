import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'success_page.dart';   // ✅

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

    // ✅ NEW: Checkbox state
    final isVerifiedChecked = useState(false);
    // ✅ Convert HEIC/HEIF/TIFF/RAW → JPG
    Future<File> convertToJpg(File file) async {
      try {
        final targetPath = file.path.replaceAll(RegExp(r'\.\w+$'), '.jpg');
        final result = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          targetPath,
          format: CompressFormat.jpeg,
          quality: 95,
        );
        if (result == null) throw Exception("HEIC conversion failed");
        return File(result.path);
      } catch (e) {
        throw Exception("Conversion failed: $e");
      }
    }

    Future<void> pickImage(ImageSource source) async {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        File file = File(pickedFile.path);
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

    // ✅ Verify & Submit
    Future<void> verifyAndSubmit() async {
      final name = nameController.text.trim();
      final email = emailController.text.trim();

      if (name.isEmpty || email.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter both name and email.")),
        );
        return;
      }

      isLoading.value = true;

      try {
        // Step 1: Get token
        final tokenResponse = await http.post(
          Uri.parse("https://uat.app.sankalptaru.org/oauth/token"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "grant_type": "client_credentials",
            "client_id": "19",
            "client_secret": "mamPzO5VbhYfSI48yoHxXrd586vEQqfgpja3hJLr"
          }),
        );

        if (tokenResponse.statusCode != 200) {
          throw Exception("Failed to get token: ${tokenResponse.body}");
        }

        final tokenData = jsonDecode(tokenResponse.body);
        final accessToken = tokenData["access_token"];

        // Step 2: Submit Name + Email
        final assignResponse = await http.post(
          Uri.parse(
              "https://uat.app.sankalptaru.org/api/business-card/assign-tree"),
          headers: {
            "Authorization": "Bearer $accessToken",
            "Content-Type": "application/json",
          },
          body: jsonEncode({"name": name, "email": email}),
        );

        if (assignResponse.statusCode == 200) {
          final resData = jsonDecode(assignResponse.body);
          final treeUrl = resData["tree_url"] ?? "";

          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SuccessPage(
                name: name,
                treeUrl: treeUrl,
              ),
            ),
          );
        } else {
          throw Exception("Error: ${assignResponse.body}");
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Submission failed: $e")),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return GestureDetector(
      onTap: () {
        // ✅ Hides keyboard when tapping outside TextField
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Tree Plant with Visiting Card",
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.green),
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
                      onPressed: () => pickImage(ImageSource.camera),
                      label: const Text("Camera"),
                    ),
                    ElevatedButton.icon(
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
                      label: const Text("Clear"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: isVerifiedChecked.value,
                      activeColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (val) {
                        isVerifiedChecked.value = val ?? false;
                      },
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      "Have you verified Name and Email?",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: isVerifiedChecked.value
                      ? verifyAndSubmit
                      : null, // ✅ Disabled until checked
                  label: const Text("Submit"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    disabledBackgroundColor: Colors.grey, // ✅ Disabled look
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
