import 'package:flutter_riverpod/flutter_riverpod.dart';

class QrScanState {
  final String? lastCode;
  final bool isProcessing;
  final String? error;
  const QrScanState({this.lastCode, this.isProcessing = false, this.error});
}

class QrScanController extends StateNotifier<QrScanState> {
  QrScanController() : super(const QrScanState());

  void setProcessing(String code) => state = QrScanState(lastCode: code, isProcessing: true);
  void setDone() => state = QrScanState(lastCode: state.lastCode, isProcessing: false);
  void setError(String e) => state = QrScanState(lastCode: state.lastCode, error: e);
  void reset() => state = const QrScanState();
}

final qrScanControllerProvider = StateNotifierProvider<QrScanController, QrScanState>((ref) => QrScanController());
