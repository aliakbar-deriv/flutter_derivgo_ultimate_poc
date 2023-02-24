import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DerivGO Ultimate',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'DerivGO Ultimate'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String message = '';
  bool isLoading = false;
  bool isDownloaded = false;
  bool enableUpdateBanner = true;
  String buttonLabel = 'Download';
  String bannerMessage = 'A new version of DerivGO Ultimate is available.';

  @override
  void initState() {
    if (isDownloaded) {
      buttonLabel = 'Install';
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 0,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (enableUpdateBanner)
            Container(
              height: kToolbarHeight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.red.withOpacity(0.3),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(bannerMessage),
                  _buildTrailingWidget(),
                ],
              ),
            ),
          Expanded(
            child: Center(
              child: Text(
                message,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          setState(() {
            isLoading = false;
            isDownloaded = false;
            buttonLabel = 'Download';
            enableUpdateBanner = true;
          });
          // final dio = Dio();
          // const String pdfUrl =
          //     "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf";
          // const String apkURL =
          //     'https://wetransfer.com/downloads/f2ee9584693c09d2ab4b36a3c765065d20230223082139/6c8eef418fa02d1930ef065299fd46b220230223082222/90ddd8';
          //
          // // final tempDir = await getTemporaryDirectory();
          // final rootDir = await getExternalStorageDirectory();
          // final String savePath = rootDir!.path + "/sample_pdf.pdf";
          // print('full path ${savePath}');
          //
          // await downloadUsingDio(dio, pdfUrl, savePath);
          // final OpenResult result = await OpenFile.open(savePath);
          // setState(() {
          //   message = '${result.type}\n:::\n' + result.message;
          // });

          // final Permission installPermission =
          //     Permission.requestInstallPackages;
          // bool installStatus = false;
          // bool ispermanetelydenied =
          //     await installPermission.isPermanentlyDenied;
          // if (ispermanetelydenied) {
          //   print("denied");
          //   await openAppSettings();
          // } else {
          //   final installStatu = await installPermission.request();
          //   installStatus = installStatu.isGranted;
          //   print(installStatus);
          // }
          // if (installStatus) {}
        },
        tooltip: 'Reset Button',
        child: const Icon(Icons.restart_alt),
      ),
    );
  }

  Future downloadUsingDio(Dio dio, String url, String savePath) async {
    try {
      Response response = await dio.get(
        url,
        onReceiveProgress: showDownloadProgress,
        //Received data with List<int>
        options: Options(
            responseType: ResponseType.bytes,
            followRedirects: false,
            validateStatus: (status) {
              return status! < 500;
            }),
      );
      print(response.headers);
      File file = File(savePath);
      var ref = file.openSync(mode: FileMode.write);
      // response.data is List<int> type
      ref.writeFromSync(response.data);
      await ref.close();
    } catch (e) {
      print(e);
    }
  }

  void showDownloadProgress(received, total) {
    if (total != -1) {
      print((received / total * 100).toStringAsFixed(0) + "%");
    }
  }

  Future<String> downloadFile(String url, String fileName, String dir) async {
    HttpClient httpClient = HttpClient();
    File file;
    String filePath = '';
    String myUrl = '';

    try {
      myUrl = url + '/' + fileName;
      var request = await httpClient.getUrl(Uri.parse(myUrl));
      var response = await request.close();
      if (response.statusCode == 200) {
        var bytes = await consolidateHttpClientResponseBytes(response);
        filePath = '$dir/$fileName';
        file = File(filePath);
        await file.writeAsBytes(bytes);
      } else {
        filePath = 'Error code: ' + response.statusCode.toString();
      }
    } catch (ex) {
      filePath = 'Can not fetch url';
    }

    return filePath;
  }

  Widget _buildTrailingWidget() {
    if (isLoading) {
      return const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(),
      );
    } else {
      return TextButton(
          child: const Text('Update'),
          onPressed: () async {
            setState(() {
              isLoading = true;
              bannerMessage = 'Downloading DerivGO Ultimate..';
            });
            await Future.delayed(const Duration(seconds: 3));
            final rootDir = await getExternalStorageDirectory();
            final String savePath = rootDir!.path + "/app-release.apk";
            print('full path ${savePath}');
            setState(() {
              bannerMessage = 'Installing DerivGO Ultimate..';
            });
            await Future.delayed(const Duration(seconds: 5));

            // await downloadUsingDio(dio, pdfUrl, savePath);
            final OpenResult result = await OpenFile.open(savePath);

            await Future.delayed(const Duration(seconds: 3));
            setState(() {
              message = '${result.type}\n:::\n' + result.message;
              enableUpdateBanner = false;
              isLoading = false;
            });
          });
    }
  }
}
