import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;

class NfcService {
  Future<String> pairAndGetPeerId() async {
    NFCTag? tag;
    try {
      tag = await FlutterNfcKit.poll(timeout: const Duration(seconds: 15));
      final peerId = tag.id;

      if (tag.ndefWritable) {
        await FlutterNfcKit.writeNDEFRecords([
          ndef.TextRecord(
            language: 'en',
            text: 'PAPO_PAIR:$peerId',
          ),
        ]);
      }

      return peerId;
    } finally {
      await FlutterNfcKit.finish();
    }
  }

  Future<String> readIncomingPaymentRequest() async {
    try {
      final tag = await FlutterNfcKit.poll(timeout: const Duration(seconds: 20));
      return tag.id;
    } finally {
      await FlutterNfcKit.finish();
    }
  }
}
