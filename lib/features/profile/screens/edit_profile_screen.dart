import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _roleController;
  late TextEditingController _bioController;
  late TextEditingController _usernameController;

  bool _isLoading = false;
  bool _isCheckingUsername = false;
  String? _usernameError;
  Uint8List? _webImage;
  String? _photoUrl;

  late final Future<List<Uint8List>> _presetAvatarsFuture;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name']);
    _roleController = TextEditingController(text: widget.userData['role']);
    _bioController = TextEditingController(text: widget.userData['bio'] ?? "");
    _usernameController = TextEditingController(
      text: widget.userData['username'] ?? "",
    );
    _photoUrl = widget.userData['photoUrl'];

    _presetAvatarsFuture = _generatePresetAvatars();
  }

  String _inferMimeType(Uint8List bytes) {
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return 'image/jpeg';
    }
    return 'image/jpeg';
  }

  Future<List<Uint8List>> _generatePresetAvatars() async {
    final avatars = <Uint8List>[];
    for (var i = 0; i < 15; i++) {
      // Keep these crisp but lightweight enough for Firestore base64 storage.
      avatars.add(await _renderAvatarPng(seed: i + 1, size: 256));
    }
    return avatars;
  }

  Future<Uint8List> _renderAvatarPng({
    required int seed,
    required int size,
  }) async {
    final rnd = Random(seed);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final s = size.toDouble();
    final center = Offset(s / 2, s / 2);
    final radius = s / 2;

    // Clip everything to a perfect circle (no "rectangle" look).
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );

    // Modern palettes (more campus / teen vibe).
    final palettes = <List<Color>>[
      const [Color(0xFF6C63FF), Color(0xFF00BFA6)],
      const [Color(0xFFFF6B6B), Color(0xFFFFB703)],
      const [Color(0xFF3A86FF), Color(0xFF8338EC)],
      const [Color(0xFF219EBC), Color(0xFFFB8500)],
      const [Color(0xFF00D084), Color(0xFF6C63FF)],
      const [Color(0xFFFF6B9D), Color(0xFF6C63FF)],
    ];
    final palette = palettes[seed % palettes.length];

    // Background gradient + subtle pattern
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(Offset(0, 0), Offset(s, s), [
        palette[0].withOpacity(0.95),
        palette[1].withOpacity(0.85),
      ]);
    canvas.drawRect(Rect.fromLTWH(0, 0, s, s), bgPaint);

    final sparklePaint = Paint()..color = Colors.white.withOpacity(0.12);
    for (var i = 0; i < 14; i++) {
      final x = rnd.nextDouble() * s;
      final y = rnd.nextDouble() * s;
      final r = (rnd.nextDouble() * 1.6 + 1.0) * (s / 128);
      canvas.drawCircle(Offset(x, y), r * 6, sparklePaint);
    }

    final outlinePaint = Paint()
      ..color = Colors.black.withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.02;

    // Shared face features
    void drawCuteEyes({required Offset c, required double r, Color? color}) {
      final eyeWhite = Paint()..color = Colors.white.withOpacity(0.95);
      final pupil = Paint()..color = (color ?? const Color(0xFF1B263B));
      final eyeOffsetX = r * 0.55;
      final eyeY = c.dy - r * 0.05;
      final eyeR = r * 0.16;
      canvas.drawCircle(Offset(c.dx - eyeOffsetX, eyeY), eyeR, eyeWhite);
      canvas.drawCircle(Offset(c.dx + eyeOffsetX, eyeY), eyeR, eyeWhite);
      canvas.drawCircle(
        Offset(c.dx - eyeOffsetX + (r * 0.03), eyeY),
        eyeR * 0.45,
        pupil,
      );
      canvas.drawCircle(
        Offset(c.dx + eyeOffsetX + (r * 0.03), eyeY),
        eyeR * 0.45,
        pupil,
      );
      // tiny highlight
      final shine = Paint()..color = Colors.white.withOpacity(0.9);
      canvas.drawCircle(
        Offset(c.dx - eyeOffsetX + eyeR * 0.25, eyeY - eyeR * 0.25),
        eyeR * 0.18,
        shine,
      );
      canvas.drawCircle(
        Offset(c.dx + eyeOffsetX + eyeR * 0.25, eyeY - eyeR * 0.25),
        eyeR * 0.18,
        shine,
      );
    }

    void drawSmile({required Offset c, required double r}) {
      final mouthPaint = Paint()
        ..color = Colors.black.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.10
        ..strokeCap = StrokeCap.round;
      final rect = Rect.fromCenter(
        center: Offset(c.dx, c.dy + r * 0.45),
        width: r * 0.95,
        height: r * 0.75,
      );
      canvas.drawArc(rect, 0.12 * pi, 0.76 * pi, false, mouthPaint);
    }

    // Avatar variants (15 distinct)
    final variant = (seed - 1) % 15;

    // Helper: draw a hoodie body
    void drawHoodie({required Color color}) {
      final hoodiePaint = Paint()..color = color.withOpacity(0.92);
      final bodyRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, s * 0.80),
          width: s * 0.86,
          height: s * 0.58,
        ),
        Radius.circular(s * 0.18),
      );
      canvas.drawRRect(bodyRect, hoodiePaint);
      // strings
      final stringPaint = Paint()
        ..color = Colors.white.withOpacity(0.55)
        ..strokeWidth = s * 0.02
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(center.dx - s * 0.06, s * 0.68),
        Offset(center.dx - s * 0.06, s * 0.76),
        stringPaint,
      );
      canvas.drawLine(
        Offset(center.dx + s * 0.06, s * 0.68),
        Offset(center.dx + s * 0.06, s * 0.76),
        stringPaint,
      );
    }

    // Human face base
    void drawHuman({
      required bool headset,
      required bool cap,
      required bool glasses,
    }) {
      final skinTones = <Color>[
        const Color(0xFFFFD6C9),
        const Color(0xFFFFC8A2),
        const Color(0xFFF2B08C),
        const Color(0xFFE0A06E),
        const Color(0xFFC68642),
        const Color(0xFF8D5524),
      ];
      final hairColors = <Color>[
        const Color(0xFF2B2B2B),
        const Color(0xFF3B2F2F),
        const Color(0xFF6B4F2A),
        const Color(0xFFA67C52),
        const Color(0xFF1D3557),
        const Color(0xFF5E548E),
      ];
      final hoodieColors = <Color>[
        const Color(0xFF0B1320),
        const Color(0xFF1F2A44),
        const Color(0xFF2D6A4F),
        const Color(0xFF3A86FF),
        const Color(0xFF8338EC),
        const Color(0xFFFF6B9D),
      ];
      final skin = skinTones[seed % skinTones.length];
      final hair = hairColors[(seed + 2) % hairColors.length];
      final hoodie = hoodieColors[(seed + 3) % hoodieColors.length];

      drawHoodie(color: hoodie);

      final faceCenter = Offset(center.dx, s * 0.44);
      final faceRadius = s * 0.24;
      final facePaint = Paint()..color = skin;
      canvas.drawCircle(faceCenter, faceRadius, facePaint);
      canvas.drawCircle(faceCenter, faceRadius, outlinePaint);

      // Hair / cap
      if (cap) {
        final capPaint = Paint()..color = Colors.black.withOpacity(0.35);
        final brim = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(faceCenter.dx, faceCenter.dy - faceRadius * 0.95),
            width: faceRadius * 2.0,
            height: faceRadius * 0.35,
          ),
          Radius.circular(faceRadius * 0.18),
        );
        canvas.drawRRect(brim, capPaint);
        final top = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(faceCenter.dx, faceCenter.dy - faceRadius * 1.15),
            width: faceRadius * 1.35,
            height: faceRadius * 0.65,
          ),
          Radius.circular(faceRadius * 0.22),
        );
        canvas.drawRRect(top, capPaint);
      } else {
        final hairPaint = Paint()..color = hair;
        final hairStyle = seed % 3;
        if (hairStyle == 0) {
          final hairRect = Rect.fromCenter(
            center: Offset(faceCenter.dx, faceCenter.dy - s * 0.06),
            width: faceRadius * 2.2,
            height: faceRadius * 1.55,
          );
          canvas.drawArc(hairRect, pi, pi, true, hairPaint);
        } else if (hairStyle == 1) {
          final path = Path();
          path.moveTo(
            faceCenter.dx - faceRadius * 1.08,
            faceCenter.dy - faceRadius * 0.18,
          );
          path.quadraticBezierTo(
            faceCenter.dx - faceRadius * 0.2,
            faceCenter.dy - faceRadius * 1.25,
            faceCenter.dx + faceRadius * 1.08,
            faceCenter.dy - faceRadius * 0.25,
          );
          path.lineTo(
            faceCenter.dx + faceRadius * 0.95,
            faceCenter.dy - faceRadius * 0.65,
          );
          path.quadraticBezierTo(
            faceCenter.dx,
            faceCenter.dy - faceRadius * 0.4,
            faceCenter.dx - faceRadius * 0.95,
            faceCenter.dy - faceRadius * 0.65,
          );
          path.close();
          canvas.drawPath(path, hairPaint);
        } else {
          final spikes = Path();
          final topY = faceCenter.dy - faceRadius * 1.05;
          spikes.moveTo(
            faceCenter.dx - faceRadius * 1.05,
            faceCenter.dy - faceRadius * 0.35,
          );
          for (var i = 0; i < 7; i++) {
            final x = faceCenter.dx - faceRadius + (i * (faceRadius * 0.32));
            final peakY = topY - (rnd.nextDouble() * faceRadius * 0.18);
            spikes.lineTo(x, peakY);
            spikes.lineTo(
              x + faceRadius * 0.17,
              faceCenter.dy - faceRadius * 0.35,
            );
          }
          spikes.lineTo(
            faceCenter.dx + faceRadius * 1.05,
            faceCenter.dy - faceRadius * 0.35,
          );
          spikes.close();
          canvas.drawPath(spikes, hairPaint);
        }
      }

      // Headset (gamer vibe)
      if (headset) {
        final band = Paint()
          ..color = Colors.black.withOpacity(0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = faceRadius * 0.18
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          Rect.fromCircle(center: faceCenter, radius: faceRadius * 1.05),
          pi,
          pi,
          false,
          band,
        );
        final cupPaint = Paint()..color = Colors.black.withOpacity(0.25);
        canvas.drawCircle(
          Offset(faceCenter.dx - faceRadius * 1.02, faceCenter.dy),
          faceRadius * 0.22,
          cupPaint,
        );
        canvas.drawCircle(
          Offset(faceCenter.dx + faceRadius * 1.02, faceCenter.dy),
          faceRadius * 0.22,
          cupPaint,
        );
      }

      // Eyes + optional glasses
      drawCuteEyes(c: faceCenter, r: faceRadius);
      if (glasses) {
        final glassPaint = Paint()
          ..color = Colors.white.withOpacity(0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = faceRadius * 0.08;
        final eyeOffsetX = faceRadius * 0.55;
        final eyeY = faceCenter.dy - faceRadius * 0.05;
        final rr = faceRadius * 0.26;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(faceCenter.dx - eyeOffsetX, eyeY),
              width: rr * 2.2,
              height: rr * 1.7,
            ),
            Radius.circular(rr * 0.4),
          ),
          glassPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(faceCenter.dx + eyeOffsetX, eyeY),
              width: rr * 2.2,
              height: rr * 1.7,
            ),
            Radius.circular(rr * 0.4),
          ),
          glassPaint,
        );
        canvas.drawLine(
          Offset(faceCenter.dx - eyeOffsetX + rr * 1.1, eyeY),
          Offset(faceCenter.dx + eyeOffsetX - rr * 1.1, eyeY),
          glassPaint,
        );
      }

      drawSmile(c: faceCenter, r: faceRadius);
    }

    void drawAnimal({
      required Color faceColor,
      required Color earColor,
      required String kind,
    }) {
      drawHoodie(color: Colors.black.withOpacity(0.18));
      final faceCenter = Offset(center.dx, s * 0.45);
      final faceRadius = s * 0.25;
      final facePaint = Paint()..color = faceColor;

      // Ears
      final earPaint = Paint()..color = earColor;
      if (kind == 'bunny') {
        final earW = faceRadius * 0.55;
        final earH = faceRadius * 1.4;
        final left = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(
              faceCenter.dx - faceRadius * 0.65,
              faceCenter.dy - faceRadius * 1.05,
            ),
            width: earW,
            height: earH,
          ),
          Radius.circular(earW * 0.6),
        );
        final right = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(
              faceCenter.dx + faceRadius * 0.65,
              faceCenter.dy - faceRadius * 1.05,
            ),
            width: earW,
            height: earH,
          ),
          Radius.circular(earW * 0.6),
        );
        canvas.drawRRect(left, earPaint);
        canvas.drawRRect(right, earPaint);
      } else {
        canvas.drawCircle(
          Offset(
            faceCenter.dx - faceRadius * 0.7,
            faceCenter.dy - faceRadius * 0.85,
          ),
          faceRadius * 0.35,
          earPaint,
        );
        canvas.drawCircle(
          Offset(
            faceCenter.dx + faceRadius * 0.7,
            faceCenter.dy - faceRadius * 0.85,
          ),
          faceRadius * 0.35,
          earPaint,
        );
      }

      // Face
      canvas.drawCircle(faceCenter, faceRadius, facePaint);
      canvas.drawCircle(faceCenter, faceRadius, outlinePaint);

      // Special markings
      if (kind == 'panda') {
        final patch = Paint()..color = Colors.black.withOpacity(0.20);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(
              faceCenter.dx - faceRadius * 0.5,
              faceCenter.dy - faceRadius * 0.05,
            ),
            width: faceRadius * 0.65,
            height: faceRadius * 0.85,
          ),
          patch,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(
              faceCenter.dx + faceRadius * 0.5,
              faceCenter.dy - faceRadius * 0.05,
            ),
            width: faceRadius * 0.65,
            height: faceRadius * 0.85,
          ),
          patch,
        );
      }
      if (kind == 'fox') {
        final cheek = Paint()..color = const Color(0xFFFFF3E0).withOpacity(0.9);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(faceCenter.dx, faceCenter.dy + faceRadius * 0.22),
            width: faceRadius * 1.25,
            height: faceRadius * 0.95,
          ),
          cheek,
        );
      }

      // Eyes + mouth
      drawCuteEyes(
        c: faceCenter,
        r: faceRadius,
        color: Colors.black.withOpacity(0.65),
      );

      final nosePaint = Paint()..color = Colors.black.withOpacity(0.35);
      canvas.drawCircle(
        Offset(faceCenter.dx, faceCenter.dy + faceRadius * 0.22),
        faceRadius * 0.08,
        nosePaint,
      );
      drawSmile(
        c: Offset(faceCenter.dx, faceCenter.dy - faceRadius * 0.02),
        r: faceRadius,
      );

      // Small blush
      final blush = Paint()..color = const Color(0xFFFF5A8A).withOpacity(0.18);
      canvas.drawCircle(
        Offset(
          faceCenter.dx - faceRadius * 0.6,
          faceCenter.dy + faceRadius * 0.25,
        ),
        faceRadius * 0.16,
        blush,
      );
      canvas.drawCircle(
        Offset(
          faceCenter.dx + faceRadius * 0.6,
          faceCenter.dy + faceRadius * 0.25,
        ),
        faceRadius * 0.16,
        blush,
      );
    }

    void drawRobot() {
      final bodyPaint = Paint()..color = Colors.white.withOpacity(0.75);
      final headCenter = Offset(center.dx, s * 0.45);
      final headW = s * 0.58;
      final headH = s * 0.46;
      final head = RRect.fromRectAndRadius(
        Rect.fromCenter(center: headCenter, width: headW, height: headH),
        Radius.circular(s * 0.14),
      );
      canvas.drawRRect(head, bodyPaint);
      canvas.drawRRect(head, outlinePaint);

      // Antenna
      final antennaPaint = Paint()
        ..color = Colors.white.withOpacity(0.7)
        ..strokeWidth = s * 0.03
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(headCenter.dx, headCenter.dy - headH * 0.62),
        Offset(headCenter.dx, headCenter.dy - headH * 0.90),
        antennaPaint,
      );
      canvas.drawCircle(
        Offset(headCenter.dx, headCenter.dy - headH * 0.95),
        s * 0.04,
        Paint()..color = Colors.white.withOpacity(0.85),
      );

      // Visor
      final visor = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(headCenter.dx, headCenter.dy - headH * 0.05),
          width: headW * 0.72,
          height: headH * 0.22,
        ),
        Radius.circular(s * 0.10),
      );
      final visorPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(headCenter.dx - headW / 2, headCenter.dy),
          Offset(headCenter.dx + headW / 2, headCenter.dy),
          [Colors.black.withOpacity(0.20), Colors.black.withOpacity(0.05)],
        );
      canvas.drawRRect(visor, visorPaint);
      canvas.drawRRect(visor, outlinePaint);

      // Eyes lights
      final eyePaint = Paint()
        ..color = const Color(0xFF00D084).withOpacity(0.9);
      canvas.drawCircle(
        Offset(headCenter.dx - headW * 0.18, headCenter.dy - headH * 0.05),
        s * 0.03,
        eyePaint,
      );
      canvas.drawCircle(
        Offset(headCenter.dx + headW * 0.18, headCenter.dy - headH * 0.05),
        s * 0.03,
        eyePaint,
      );

      // Bottom hoodie
      drawHoodie(color: Colors.black.withOpacity(0.20));
    }

    void drawAstronaut() {
      // Helmet
      final helmetCenter = Offset(center.dx, s * 0.44);
      final helmetR = s * 0.28;
      final helmetPaint = Paint()..color = Colors.white.withOpacity(0.75);
      canvas.drawCircle(helmetCenter, helmetR, helmetPaint);
      canvas.drawCircle(helmetCenter, helmetR, outlinePaint);

      // Visor
      final visorPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(helmetCenter.dx - helmetR, helmetCenter.dy - helmetR),
          Offset(helmetCenter.dx + helmetR, helmetCenter.dy + helmetR),
          [Colors.black.withOpacity(0.22), Colors.black.withOpacity(0.05)],
        );
      final visor = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(helmetCenter.dx, helmetCenter.dy),
          width: helmetR * 1.35,
          height: helmetR * 1.05,
        ),
        Radius.circular(helmetR * 0.40),
      );
      canvas.drawRRect(visor, visorPaint);

      // Stars
      final starPaint = Paint()..color = Colors.white.withOpacity(0.55);
      for (var i = 0; i < 6; i++) {
        canvas.drawCircle(
          Offset(rnd.nextDouble() * s, rnd.nextDouble() * s * 0.55),
          s * 0.01 * (1 + rnd.nextDouble() * 1.5),
          starPaint,
        );
      }

      drawHoodie(color: Colors.black.withOpacity(0.22));
    }

    void drawPenguin() {
      final bodyCenter = Offset(center.dx, s * 0.52);
      final body = Rect.fromCenter(
        center: bodyCenter,
        width: s * 0.56,
        height: s * 0.70,
      );
      final bodyPaint = Paint()..color = Colors.black.withOpacity(0.55);
      canvas.drawOval(body, bodyPaint);
      canvas.drawOval(body, outlinePaint);
      final bellyPaint = Paint()..color = Colors.white.withOpacity(0.85);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(bodyCenter.dx, bodyCenter.dy + s * 0.04),
          width: s * 0.34,
          height: s * 0.46,
        ),
        bellyPaint,
      );
      // Face
      final headCenter = Offset(center.dx, s * 0.38);
      final headR = s * 0.20;
      canvas.drawCircle(headCenter, headR, bodyPaint);
      canvas.drawCircle(headCenter, headR, outlinePaint);
      drawCuteEyes(
        c: headCenter,
        r: headR,
        color: Colors.black.withOpacity(0.75),
      );
      // Beak
      final beak = Paint()..color = const Color(0xFFFFB703).withOpacity(0.95);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(headCenter.dx, headCenter.dy + headR * 0.30),
          width: headR * 0.55,
          height: headR * 0.35,
        ),
        beak,
      );
    }

    // Build the selected variant
    switch (variant) {
      case 0:
        drawAnimal(
          faceColor: const Color(0xFFFFF3E0).withOpacity(0.95),
          earColor: const Color(0xFF2B2B2B).withOpacity(0.65),
          kind: 'cat',
        );
        break;
      case 1:
        drawAnimal(
          faceColor: const Color(0xFFFFC46A).withOpacity(0.95),
          earColor: const Color(0xFFB85C38).withOpacity(0.85),
          kind: 'fox',
        );
        break;
      case 2:
        drawAnimal(
          faceColor: Colors.white.withOpacity(0.93),
          earColor: Colors.black.withOpacity(0.55),
          kind: 'panda',
        );
        break;
      case 3:
        drawAnimal(
          faceColor: const Color(0xFFF8F9FA).withOpacity(0.96),
          earColor: const Color(0xFF9D4EDD).withOpacity(0.55),
          kind: 'bunny',
        );
        break;
      case 4:
        drawAnimal(
          faceColor: const Color(0xFFD8F3DC).withOpacity(0.93),
          earColor: const Color(0xFF2D6A4F).withOpacity(0.75),
          kind: 'dog',
        );
        break;
      case 5:
        drawAnimal(
          faceColor: const Color(0xFFDEE2E6).withOpacity(0.95),
          earColor: const Color(0xFF495057).withOpacity(0.70),
          kind: 'koala',
        );
        break;
      case 6:
        drawAnimal(
          faceColor: const Color(0xFFFFE08A).withOpacity(0.95),
          earColor: const Color(0xFF5A3E2B).withOpacity(0.75),
          kind: 'tiger',
        );
        // Tiger stripes
        final stripePaint = Paint()..color = Colors.black.withOpacity(0.18);
        final c = Offset(center.dx, s * 0.45);
        final r = s * 0.25;
        for (var i = -2; i <= 2; i++) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(c.dx + (i * r * 0.22), c.dy - r * 0.05),
                width: r * 0.10,
                height: r * 0.55,
              ),
              Radius.circular(r * 0.06),
            ),
            stripePaint,
          );
        }
        break;
      case 7:
        drawPenguin();
        break;
      case 8:
        drawRobot();
        break;
      case 9:
        drawAstronaut();
        break;
      case 10:
        drawHuman(headset: true, cap: false, glasses: false);
        break;
      case 11:
        drawHuman(headset: false, cap: true, glasses: false);
        break;
      case 12:
        drawHuman(headset: false, cap: false, glasses: true);
        break;
      case 13:
        drawHuman(headset: false, cap: false, glasses: false);
        break;
      default:
        // Cute alien mascot
        drawHoodie(color: Colors.black.withOpacity(0.18));
        final faceCenter = Offset(center.dx, s * 0.45);
        final faceRadius = s * 0.25;
        final facePaint = Paint()
          ..color = const Color(0xFFB7F7D1).withOpacity(0.95);
        canvas.drawCircle(faceCenter, faceRadius, facePaint);
        canvas.drawCircle(faceCenter, faceRadius, outlinePaint);
        // antenna
        final antennaPaint = Paint()
          ..color = Colors.white.withOpacity(0.55)
          ..strokeWidth = s * 0.03
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(
            faceCenter.dx - faceRadius * 0.25,
            faceCenter.dy - faceRadius * 0.95,
          ),
          Offset(
            faceCenter.dx - faceRadius * 0.55,
            faceCenter.dy - faceRadius * 1.25,
          ),
          antennaPaint,
        );
        canvas.drawCircle(
          Offset(
            faceCenter.dx - faceRadius * 0.60,
            faceCenter.dy - faceRadius * 1.30,
          ),
          s * 0.03,
          Paint()..color = Colors.white.withOpacity(0.85),
        );
        drawCuteEyes(
          c: faceCenter,
          r: faceRadius,
          color: Colors.black.withOpacity(0.55),
        );
        drawSmile(c: faceCenter, r: faceRadius);
    }

    // Premium highlight ring
    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.045;
    canvas.drawCircle(center, radius - (s * 0.03), ringPaint);

    canvas.restore();

    final picture = recorder.endRecording();
    final img = await picture.toImage(size, size);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _openAvatarPicker() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Choose a profile avatar',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<Uint8List>>(
                  future: _presetAvatarsFuture,
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final avatars = snap.data!;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: avatars.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemBuilder: (context, index) {
                        final bytes = avatars[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () {
                            setState(() {
                              _webImage = bytes;
                            });
                            Navigator.pop(context);
                          },
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: MemoryImage(bytes),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Upload from gallery instead'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Check username availability
  Future<void> _checkUsernameAvailability(String username) async {
    if (username.isEmpty) {
      setState(() => _usernameError = null);
      return;
    }

    setState(() => _isCheckingUsername = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      // If any user exists with this username, and it's not the current user
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      final isTaken = snapshot.docs.any((doc) => doc.id != currentUid);

      setState(() {
        _usernameError = isTaken ? 'Username already taken' : null;
        _isCheckingUsername = false;
      });
    } catch (e) {
      setState(() {
        _usernameError = 'Error checking username';
        _isCheckingUsername = false;
      });
    }
  }

  // 1. Pick Image
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // Using simple gallery source with compression
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 20, // KEEP THIS: Compresses image to avoid database limits
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _webImage = bytes;
      });
    }
  }

  // 2. The "Smart Hack": Convert Image to Text String
  String? _convertImageToBase64() {
    if (_webImage == null) return null;
    String base64String = base64Encode(_webImage!);
    final mime = _inferMimeType(_webImage!);
    return "data:$mime;base64,$base64String";
  }

  // 3. Save to Database
  void _updateProfile() async {
    // Validate username if changed
    if (_usernameError != null && _usernameError!.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_usernameError!)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Prepare basic data
      Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'role': _roleController.text.trim(),
        'bio': _bioController.text.trim(),
        'username': _usernameController.text.trim(),
      };

      // If a new image was picked, turn it into text and save it
      String? newImageString = _convertImageToBase64();
      if (newImageString != null) {
        updateData['photoUrl'] = newImageString;
      }

      // Update Firestore directly
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update(updateData);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Update failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // IMAGE PICKER
            GestureDetector(
              onTap: _openAvatarPicker,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade200,
                    // If we have a new pick, show it. If not, show existing URL.
                    backgroundImage: _webImage != null
                        ? MemoryImage(_webImage!)
                        : (_photoUrl != null &&
                              _photoUrl!.toString().startsWith('data:'))
                        ? MemoryImage(
                            base64Decode(_photoUrl!.toString().split(',')[1]),
                          ) // Decode stored text
                        : null,
                    child:
                        (_webImage == null &&
                            (_photoUrl == null || _photoUrl!.isEmpty))
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6C63FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openAvatarPicker,
                    icon: const Icon(Icons.face_retouching_natural_rounded),
                    label: const Text('Choose Avatar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Upload Photo'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              onChanged: _checkUsernameAvailability,
              decoration: InputDecoration(
                labelText: "Username",
                border: const OutlineInputBorder(),
                helperText: _usernameError,
                helperStyle: TextStyle(
                  color: _usernameError != null ? Colors.red : Colors.green,
                ),
                suffixIcon: _isCheckingUsername
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _usernameError == null &&
                          _usernameController.text.isNotEmpty
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _roleController,
              decoration: const InputDecoration(
                labelText: "Role/Year",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Bio",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),

            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _updateProfile,
                      child: const Text("Save Changes"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
