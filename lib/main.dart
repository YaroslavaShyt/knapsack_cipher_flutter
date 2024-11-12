import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MHKCrypto {
  late List<BigInt> w, b;
  late BigInt q, r;
  Random rand = Random();
  static const int MAX_CHARS = 150;
  static const int BINARY_LENGTH = MAX_CHARS * 8;

  MHKCrypto() {
    genKeys();
  }

  void genKeys() {
    int maxBits = 50;
    w = List<BigInt>.filled(BINARY_LENGTH, BigInt.zero);
    BigInt sum = BigInt.zero;

    w[0] = BigInt.from(rand.nextInt(maxBits) + 1);
    sum = w[0];

    for (int i = 1; i < w.length; i++) {
      w[i] = sum + BigInt.from(rand.nextInt(maxBits) + 1);
      sum = sum + w[i];
    }

    q = sum + BigInt.from(rand.nextInt(maxBits) + 1);
    r = q - BigInt.one;

    b = List<BigInt>.filled(BINARY_LENGTH, BigInt.zero);
    for (int i = 0; i < b.length; i++) {
      b[i] = (w[i] * r) % q;
    }
  }

  String encryptMsg(String message) {
    if (message.length > MAX_CHARS) {
      throw ArgumentError("Maximum message length allowed is $MAX_CHARS.");
    }
    if (message.isEmpty) {
      throw ArgumentError("Cannot encrypt an empty string.");
    }

    StringBuffer msgBinaryBuffer = StringBuffer();
    for (int i = 0; i < message.length; i++) {
      msgBinaryBuffer.write(message.codeUnitAt(i).toRadixString(2).padLeft(8, '0'));
    }
    String msgBinary = msgBinaryBuffer.toString();

    if (msgBinary.length < BINARY_LENGTH) {
      msgBinary = msgBinary.padLeft(BINARY_LENGTH, '0');
    }

    BigInt result = BigInt.zero;
    for (int i = 0; i < msgBinary.length; i++) {
      result += b[i] * BigInt.from(int.parse(msgBinary[i]));
    }

    return result.toString();
  }

  String decryptMsg(String ciphertext) {
    BigInt tmp = BigInt.parse(ciphertext) % q;
    tmp = tmp * r.modInverse(q) % q;
    List<int> decryptedBinary = List.filled(w.length, 0);

    for (int i = w.length - 1; i >= 0; i--) {
      if (w[i] <= tmp) {
        tmp -= w[i];
        decryptedBinary[i] = 1;
      }
    }

    StringBuilder sb = StringBuilder();
    for (int i = 0; i < decryptedBinary.length; i++) {
      sb.write(decryptedBinary[i].toString());
    }

    String decryptedBinaryStr = sb.toString();
    List<int> byteList = [];
    for (int i = 0; i < decryptedBinaryStr.length; i += 8) {
      String byteStr = decryptedBinaryStr.substring(i, i + 8);
      byteList.add(int.parse(byteStr, radix: 2));
    }

    return utf8.decode(byteList);
  }
}

class StringBuilder {
  StringBuffer _sb = StringBuffer();

  void write(String str) {
    _sb.write(str);
  }

  @override
  String toString() => _sb.toString();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MHK Cryptosystem',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final MHKCrypto crypto = MHKCrypto();
  final TextEditingController _controller = TextEditingController();
  String _encryptedMessage = '';
  String _decryptedMessage = '';

  void _encrypt() {
    setState(() {
      _encryptedMessage = crypto.encryptMsg(_controller.text);
    });
  }

  void _decrypt() {
    setState(() {
      _decryptedMessage = crypto.decryptMsg(_encryptedMessage);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MHK Cryptosystem'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Enter message to encrypt',
                border: OutlineInputBorder(),
              ),
            ),
           const  SizedBox(height: 16),
            ElevatedButton(
              onPressed: _encrypt,
              child: const Text('Encrypt Message'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Encrypted Message:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SelectableText(_encryptedMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _decrypt,
              child: const Text('Decrypt Message'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Decrypted Message:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SelectableText(_decryptedMessage),
          ],
        ),
      ),
    );
  }
}
