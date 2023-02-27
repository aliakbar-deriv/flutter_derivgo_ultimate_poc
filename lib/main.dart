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
  bool enableUpdateBanner = false;
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
                  Expanded(child: Text(bannerMessage)),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          setState(() {
            isLoading = false;
            isDownloaded = false;
            buttonLabel = 'Download';
            enableUpdateBanner = true;
          });
        },
        tooltip: 'Reset Button',
        label: const Text('TRY NEW VERSION'),
        icon: const Icon(Icons.restart_alt),
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
            // const Permission packageInstallPermission =
            //     Permission.requestInstallPackages;
            // bool isPermanentlyDenied =
            //     await packageInstallPermission.isPermanentlyDenied;
            //
            // if (isPermanentlyDenied) {
            //   print("Permanently denied");
            //   await openAppSettings();
            // } else {
            //   final packageInstallPermissionStatus =
            //       await packageInstallPermission.request();
            //   if (packageInstallPermissionStatus.isGranted) {
            //      //TODO: Download and install action here
            //   }
            // }

            setState(() {
              isLoading = true;
              bannerMessage = 'Downloading DerivGO Ultimate..';
            });

            final dio = Dio();
            const String apkTestUrl =
                'https://firebasestorage.googleapis.com/v0/b/derivgo-ultimate.appspot.com/o/derivgo_ultimate_v2_0.apk?alt=media&token=61871e21-b3fa-4da0-ace0-e95f3d59e99f';
            final tempDir = await getTemporaryDirectory();
            final String savePath =
                tempDir.path + "/derivgo_ultimate_v2_0.apk";
            print('APK file path $savePath');
            await downloadUsingDio(dio, apkTestUrl, savePath);
            setState(() {
              bannerMessage = 'Installing DerivGO Ultimate..';
            });
            await Future.delayed(const Duration(seconds: 2));
            final OpenResult result = await OpenFile.open(savePath);
            setState(() {
              message = '${result.type}\n:::\n' + result.message;
              enableUpdateBanner = false;
              isLoading = false;
            });

          });
    }
  }
}
