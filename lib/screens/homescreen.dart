import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf_render/pdf_render.dart';
import 'package:share_plus/share_plus.dart';

import '../controllers/pdfcontroller.dart';
import '../controllers/statecontroler.dart';
import 'pdfviewpage.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});
  final PdfController _pdfController = Get.put(PdfController());
  final stateController = Get.find<StateController>();

  Future<Widget> generatePdfThumbnail(String path) async {
    PdfDocument pdfDocument = await PdfDocument.openFile(path);
    final pdfPage =
        await pdfDocument.getPage(1); // Get the first page for thumbnail
    final pdfImage = await pdfPage.render(
      width: int.tryParse(pdfPage.width.toString()),
      height: int.tryParse(pdfPage.height.toString()),
      fullHeight: pdfPage.height,
      fullWidth: pdfPage.width,
    );
    await pdfDocument.dispose();
    await pdfImage.createImageIfNotAvailable();

    return RawImage(
      image: pdfImage.imageIfAvailable,
      fit: BoxFit.contain,
      height: 100,
      width: 80,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Scan to PDF",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton.outlined(
              onPressed: () => _pdfController.listPdfFiles(),
              icon: const Icon(Icons.refresh_rounded)),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 1,
                child: const Text('Developer'),
                onTap: () => stateController.launchDevProfile(),
              ),
              PopupMenuItem(
                value: 2,
                onTap: () => stateController.privacyPolicyLauncher(),
                child: const Text('Privacy Policy'),
              ),
            ],
            onSelected: (value) async {
              if (value == 1) {
              } else {}
            },
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            backgroundColor: Colors.red.shade700,
            onPressed: () {
              stateController.newPdfCreation();
            },
            tooltip: "Create PDF from Camera",
            child: const Icon(Icons.add_a_photo_outlined, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            backgroundColor: Colors.red.shade700,
            onPressed: () {
              stateController
                  .pickImagesFromGallery(); // Call this method to pick images from the gallery
            },
            tooltip: "Create PDF from Gallery",
            child: const Icon(Icons.image_outlined, color: Colors.white),
          ),
        ],
      ),
      body: Obx(() {
        if (_pdfController.pdfFiles.isEmpty) {
          return const Center(
              child: Text("No pdf files are there Please create one to see"));
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: ListView.separated(
              separatorBuilder: (context, index) => const SizedBox(
                height: 12,
              ),
              itemCount: _pdfController.pdfFiles.length,
              itemBuilder: (context, index) {
                return pdfListcard(index);
              },
            ),
          );
        }
      }),
    );
  }

  Widget pdfListcard(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              offset: const Offset(3, 3.0),
              blurRadius: 1.0,
            ),
          ],
        ),
        child: Row(
          children: [
            InkWell(
              onTap: () {
                Get.to(
                  () => PDFScreen(
                    path: _pdfController.pdfFiles[index].path,
                  ),
                );
              },
              child: FutureBuilder<Widget>(
                future:
                    generatePdfThumbnail(_pdfController.pdfFiles[index].path),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return snapshot.data ??
                        const Icon(Icons.picture_as_pdf, size: 80);
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    child: Text(
                      _pdfController.pdfFiles[index].path.split('/').last,
                      // overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () async {
                          final file =
                              File(_pdfController.pdfFiles[index].path);
                          await file
                              .delete()
                              .then((_) => _pdfController.listPdfFiles());
                        },
                        icon: const Icon(
                          Icons.delete_outline_outlined,
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await Share.shareXFiles(
                              [XFile(_pdfController.pdfFiles[index].path)]);
                        },
                        icon: const Icon(Icons.share_outlined),
                      ),
                      IconButton(
                        onPressed: () {
                          stateController.saveToDownload(
                              _pdfController.pdfFiles[index].path);
                        },
                        icon: const Icon(Icons.file_download_outlined),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
