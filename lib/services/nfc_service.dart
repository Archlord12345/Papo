import 'dart:convert';

import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

class NfcService {
  Future<String> pairAndGetPeerId() async {
    NFCTag? tag;
    try {
      tag = await FlutterNfcKit.poll(timeout: const Duration(seconds: 15));
      final peerId = tag.id;
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
