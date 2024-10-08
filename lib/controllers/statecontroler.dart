import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_settings_plus/core/open_settings_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import 'pdfcontroller.dart';

class StateController extends GetxController {
  final setting = const OpenSettingsPlusAndroid();
  late PdfController _pdfController;
  late pw.Document pdf;
  final filenameController = TextEditingController();

  final ImagePicker _picker = ImagePicker(); // Initialize ImagePicker

  static const String _pdfFolderName = 'PDFs';

  Future<String> getAppDirectory() async {
    Directory? directory = await getApplicationDocumentsDirectory();
    final pdfDir = Directory(p.join(directory.path, _pdfFolderName));
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }
    return pdfDir.path;
  }

  Future<bool> checkAndroidVersionAndPermission() async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    final deviceInfo = await deviceInfoPlugin.androidInfo;
    final androidVersion = deviceInfo.version.sdkInt;

    if (androidVersion >= 30) {
      return requestManageExternalStoragePermission();
    } else {
      return requestDownloadDirectoryPermission();
    }
  }

  Future<bool> requestDownloadDirectoryPermission() async {
    final permissionStatus = await Permission.storage.status;
    if (permissionStatus.isGranted) {
      return true;
    } else {
      final permissionRequest = await Permission.storage.request();
      if (permissionRequest.isGranted) {
        return true;
      } else if (permissionRequest.isDenied) {
        return false;
      } else if (permissionRequest.isPermanentlyDenied) {
        Get.defaultDialog(
          title: "Permission Denied",
          confirm: ElevatedButton(
            onPressed: () {
              setting.internalStorage();
            },
            child: const Text('Open Settings'),
          ),
        );
        return false;
      }
    }
    return false;
  }

  Future<bool> requestManageExternalStoragePermission() async {
    final permissionStatus = await Permission.manageExternalStorage.status;
    if (permissionStatus.isGranted) {
      return true;
    } else {
      final permissionRequest =
          await Permission.manageExternalStorage.request();
      if (permissionRequest.isGranted) {
        return true;
      } else if (permissionRequest.isDenied) {
        return false;
      } else if (permissionRequest.isPermanentlyDenied) {
        Get.defaultDialog(
          title: "Permission Denied",
          confirm: ElevatedButton(
            onPressed: () {
              setting.internalStorage();
            },
            child: const Text('Open Settings'),
          ),
        );
        return false;
      }
    }
    return false;
  }

  void newPdfCreation() {
    creatNewPdf().then((pdfData) {
      getAppDirectory().then((path) {
        Get.defaultDialog(
          title: "Give Pdf Name",
          content: TextField(
            controller: filenameController,
          ),
          confirm: ElevatedButton(
            onPressed: () {
              Get.back();
            },
            child: const Text("Save"),
          ),
        ).then((_) {
          final filename = filenameController.text.isEmpty
              ? const Uuid().v4()
              : filenameController.text;
          File('$path/$filename.pdf')
              .writeAsBytes(pdfData, flush: true)
              .then((file) {
            filenameController.clear();
            log('PDF saved to: ${file.path}');
          });
          _pdfController.listPdfFiles();
        });
      });
    });
  }

  Future<Uint8List> creatNewPdf() async {
    List<String> pictures = await CunningDocumentScanner.getPictures() ?? [];
    if (pictures.isEmpty) {
      throw Exception('No pictures were scanned');
    }
    pdf = pw.Document();

    for (var file in pictures) {
      final fileData = File(file).readAsBytesSync();
      final image = pw.MemoryImage(fileData);
      pdf.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(10),
          build: (context) =>
              pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
        ),
      );
    }

    final pdfData = await pdf.save();
    Get.snackbar("Success", "Your PDF is created");
    return pdfData;
  }

  @override
  void onInit() {
    pdf = pw.Document();
    super.onInit();
  }

  @override
  void onReady() {
    _pdfController = Get.find<PdfController>();
    deleteOldPDFs();
    super.onReady();
  }

  Future<void> launchDevProfile() async {
    if (!await launchUrl(
        Uri.parse("https://www.linkedin.com/in/jayesh-ghadge/"))) {
      Get.snackbar("Error", "Error launching URL");
      throw Exception(
          'Could not launch https://www.linkedin.com/in/jayesh-ghadge/');
    }
  }

  Future<void> privacyPolicyLauncher() async {
    if (!await launchUrl(Uri.parse(
        "https://www.termsfeed.com/live/02b38606-2789-48b5-861c-a54b4a8b1be5"))) {
      Get.snackbar("Error", "Error launching URL");
      throw Exception(
          'Could not launch https://www.termsfeed.com/live/02b38606-2789-48b5-861c-a54b4a8b1be5');
    }
  }

  Future<void> deleteOldPDFs({int olderThanDays = 30}) async {
    final path = await getAppDirectory();
    final dir = Directory(path);
    final now = DateTime.now();

    await for (var fileSystem in dir.list()) {
      if (fileSystem is File && fileSystem.path.endsWith('.pdf')) {
        final lastModified = await fileSystem.lastModified();
        final age = now.difference(lastModified).inDays;

        if (age > olderThanDays) {
          try {
            await fileSystem.delete();
          } catch (e) {
            Get.snackbar("Error", "Error deleting old file");
          }
        }
      }
    }
  }

  Future<void> saveToDownload(String path) async {
    if (await checkAndroidVersionAndPermission()) {
      var downloadDirectory = await getDownloadsDirectory();

      String newPath = "";
      List<String> folders;
      if (downloadDirectory != null) {
        folders = downloadDirectory.path.split("/");
        newPath = "";
        for (int i = 1; i < folders.length; i++) {
          String folder = folders[i];
          if (folder != "Android") {
            log(folder);
            newPath += "/$folder";
          } else {
            break;
          }
        }
        newPath = "$newPath/ScanToPDF";
        downloadDirectory = Directory(newPath);
        log(downloadDirectory.path);

        try {
          if (!await downloadDirectory.exists()) {
            await downloadDirectory.create(recursive: true);
          }
          await _saveFile(File(path), downloadDirectory);
        } catch (e) {
          Get.snackbar("Error", "Error creating or accessing directory: $e");
        }
      }
    } else {
      Get.snackbar("Error", "Please provide storage permission from settings");
    }
  }

  Future<void> _saveFile(File file, Directory pdfDir) async {
    String filename = filenameController.text.isEmpty
        ? const Uuid().v4()
        : filenameController.text;
    if (filenameController.text.isEmpty) {
      await Get.defaultDialog(
        title: "Give PDF Name",
        content: TextField(
          controller: filenameController,
        ),
        confirm: ElevatedButton(
          onPressed: () => Get.back(),
          child: const Text("Save"),
        ),
      );
      filename = filenameController.text.isEmpty
          ? const Uuid().v4()
          : filenameController.text;
    }
    try {
      await File('${pdfDir.path}/$filename.pdf')
          .writeAsBytes(file.readAsBytesSync());
      print(pdfDir.path);
      filenameController.clear();
      Fluttertoast.showToast(msg: "File Saved");
    } catch (e) {
      Get.snackbar("Error", "Error saving file: $e");
    }
  }

  // Method to select images from the gallery and create PDF
  Future<void> pickImagesFromGallery() async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images == null || images.isEmpty) {
      Get.snackbar("Error", "No images selected");
      return;
    }

    pdf = pw.Document();
    for (var image in images) {
      final imageData = File(image.path).readAsBytesSync();
      final pwImage = pw.MemoryImage(imageData);
      pdf.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(10),
          build: (context) =>
              pw.Center(child: pw.Image(pwImage, fit: pw.BoxFit.contain)),
        ),
      );
    }

    final pdfData = await pdf.save();
    Get.snackbar("Success", "Your PDF from gallery images is created");

    // Save PDF to the device
    savePdfToFile(pdfData);
  }

  Future<void> savePdfToFile(Uint8List pdfData) async {
    final path = await getAppDirectory();
    Get.defaultDialog(
      title: "Give Pdf Name",
      content: TextField(
        controller: filenameController,
      ),
      confirm: ElevatedButton(
        onPressed: () {
          Get.back();
        },
        child: const Text("Save"),
      ),
    ).then((_) {
      final filename = filenameController.text.isEmpty
          ? const Uuid().v4()
          : filenameController.text;
      File('$path/$filename.pdf')
          .writeAsBytes(pdfData, flush: true)
          .then((file) {
        filenameController.clear();
        log('PDF saved to: ${file.path}');
      });
      _pdfController.listPdfFiles();
    });
  }
}
