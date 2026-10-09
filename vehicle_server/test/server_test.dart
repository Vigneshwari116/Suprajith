import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:test/test.dart';

void main() {
  final port = '8085'; // Conflict se bachne ke liye test ke liye alag port
  final host = 'http://127.0.0.1:$port';
  late Process p;

  setUp(() async {
    p = await Process.start(
      'dart',
      ['run', 'bin/server.dart'],
      environment: {'PORT': port},
    );
    // Server startup log aane ka wait karein
    await p.stdout.first;
    // Thoda sa delay taaki SQLite aur server socket completely ready ho sakein
    await Future.delayed(const Duration(milliseconds: 500));
  });

  tearDown(() async {
    p.kill();
  });

  test('Ping Handshake Test', () async {
    final response = await get(Uri.parse('$host/api/ping'));
    expect(response.statusCode, 200);
    final data = jsonDecode(response.body);
    expect(data['status'], 'online');
    expect(data['service'], 'Svenska Print Server');
  });

  test('Master List Test', () async {
    final response = await get(Uri.parse('$host/api/masters'));
    expect(response.statusCode, 200);
    final data = jsonDecode(response.body);
    expect(data['status'], 'success');
    expect(data['data'], isA<List>());
  });

  test('Print Validation - Missing Model', () async {
    final response = await post(
      Uri.parse('$host/api/print'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'model': ''}),
    );
    expect(response.statusCode, 400);
  });

  test('404 Route Test', () async {
    final response = await get(Uri.parse('$host/unknown_route'));
    expect(response.statusCode, 404);
  });
}