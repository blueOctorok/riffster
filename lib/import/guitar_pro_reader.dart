import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:webview_windows/webview_windows.dart';

import 'imported_score.dart';

/// Reads a Guitar Pro file by handing the bytes to alphaTab.
///
/// The web view is never shown. It exists so a JavaScript library can
/// parse the file. The practice screen only receives [ImportedScore].
class GuitarProReader {
  WebviewController? _controller;
  StreamSubscription<LoadingState>? _loading;
  StreamSubscription<WebErrorStatus>? _errors;
  var _pageReady = false;

  Future<ImportedScore> read(Uint8List bytes) async {
    final controller = await _ensurePage();
    final script = 'riffsterRead(${jsonEncode(base64Encode(bytes))})';
    final result = await controller.executeScript(script);
    if (result is! Map) {
      throw const FormatException('Could not read that Guitar Pro file.');
    }
    final json = Map<String, dynamic>.from(
      result.map((key, value) => MapEntry(key.toString(), value)),
    );
    final error = json['error'];
    if (error != null) {
      throw FormatException(error.toString());
    }
    return ImportedScore.fromJson(json);
  }

  void dispose() {
    _loading?.cancel();
    _errors?.cancel();
    _controller?.dispose();
    _controller = null;
    _pageReady = false;
  }

  Future<WebviewController> _ensurePage() async {
    final existing = _controller;
    if (existing != null && _pageReady) return existing;

    final version = await WebviewController.getWebViewVersion();
    if (version == null) {
      throw StateError(
        'WebView2 is missing, so Guitar Pro files cannot be read.',
      );
    }

    final controller = WebviewController();
    await controller.initialize();
    _controller = controller;

    final folder = _readerFolder();
    await controller.addVirtualHostNameMapping(
      'gp.riffster.test',
      folder.path,
      WebviewHostResourceAccessKind.deny,
    );
    await controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);

    final ready = Completer<void>();
    _loading = controller.loadingState.listen((state) {
      if (state == LoadingState.navigationCompleted && !ready.isCompleted) {
        ready.complete();
      }
    });
    _errors = controller.onLoadError.listen((status) {
      if (!ready.isCompleted) {
        ready.completeError(
          StateError('Could not load the file reader ($status).'),
        );
      }
    });

    await controller.loadUrl('https://gp.riffster.test/index.html');
    await ready.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        throw StateError('The file reader took too long to start.');
      },
    );
    _pageReady = true;
    return controller;
  }

  Directory _readerFolder() {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final separator = Platform.pathSeparator;
    final folder = Directory(
      '$exeDir${separator}data${separator}flutter_assets${separator}assets${separator}gp_reader',
    );
    if (!folder.existsSync()) {
      throw StateError('The Guitar Pro reader files are missing.');
    }
    return folder;
  }
}
