import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pulguinha/theme/app_colors.dart';
import 'package:pulguinha/widgets/pulguinha_widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrDisplayCard extends StatelessWidget {
  const QrDisplayCard({
    super.key,
    required this.data,
    required this.titulo,
    this.subtitulo,
    this.fullScreen = false,
  });

  final String data;
  final String titulo;
  final String? subtitulo;
  final bool fullScreen;

  @override
  Widget build(BuildContext context) {
    final qr = QrImageView(
      data: data,
      version: QrVersions.auto,
      size: fullScreen ? 300 : 180,
      backgroundColor: Colors.white,
      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF111111)),
      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF111111)),
    );

    if (fullScreen) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.card,
          foregroundColor: AppColors.white,
          title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const PulguinhaLogo(size: 112, showShadow: true),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: AppColors.neon.withValues(alpha: 0.35), blurRadius: 32)],
                  ),
                  child: qr,
                ),
                const SizedBox(height: 24),
                if (subtitulo != null)
                  Text(subtitulo!, style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('Alunos: abram Check-in e escaneiem este QR', style: TextStyle(color: AppColors.gray, fontSize: 13)),
              ],
            ),
          ),
        ),
      );
    }

    return PulguinhaCard(
      child: Column(
        children: [
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.white)),
          if (subtitulo != null) ...[
            const SizedBox(height: 4),
            Text(subtitulo!, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: qr,
          ),
        ],
      ),
    );
  }
}

/// Scanner QR multiplataforma (Android, iOS, Web) + entrada manual para desktop.
class PulguinhaQrScanner extends StatefulWidget {
  const PulguinhaQrScanner({
    super.key,
    required this.onScan,
    this.hint = 'Aponte para o QR code da aula',
  });

  final ValueChanged<String> onScan;
  final String hint;

  @override
  State<PulguinhaQrScanner> createState() => _PulguinhaQrScannerState();
}

class _PulguinhaQrScannerState extends State<PulguinhaQrScanner> {
  bool _handled = false;
  bool _cameraError = false;
  bool _showManual = false;
  final _manualCtrl = TextEditingController();
  MobileScannerController? _controller;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  void _initCamera() {
    try {
      _controller = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
    } catch (_) {
      _cameraError = true;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }

  void _handleScan(String raw) {
    if (_handled || raw.trim().isEmpty) return;
    _handled = true;
    widget.onScan(raw.trim());
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) _handled = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_cameraError && _controller != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                SizedBox(
                  height: kIsWeb ? 240 : 280,
                  child: MobileScanner(
                    controller: _controller,
                    errorBuilder: (context, error) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _cameraError = true);
                      });
                      return _cameraFallback();
                    },
                    onDetect: (capture) {
                      for (final barcodes in capture.barcodes) {
                        final raw = barcodes.rawValue;
                        if (raw != null && raw.isNotEmpty) {
                          _handleScan(raw);
                          break;
                        }
                      }
                    },
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.black.withValues(alpha: 0.6),
                    child: Text(widget.hint, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.neon, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
                Positioned.fill(child: CustomPaint(painter: _ScannerFramePainter())),
              ],
            ),
          )
        else
          _cameraFallback(),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => setState(() => _showManual = !_showManual),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_showManual ? Icons.expand_less : Icons.keyboard, size: 16, color: AppColors.gray),
              const SizedBox(width: 6),
              Text(
                _showManual ? 'Ocultar código manual' : 'Sem câmera? Digite o código',
                style: const TextStyle(fontSize: 12, color: AppColors.gray, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        if (_showManual) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _manualCtrl,
            decoration: const InputDecoration(
              hintText: 'pulguinha:aula:5:2026-06-13',
              prefixIcon: Icon(Icons.qr_code, color: AppColors.gray),
            ),
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          NeonButton(
            label: 'Confirmar código',
            fullWidth: true,
            onPressed: () => _handleScan(_manualCtrl.text),
          ),
        ],
      ],
    );
  }

  Widget _cameraFallback() {
    return PulguinhaCard(
      child: Column(
        children: [
          const Text('📷', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(
            kIsWeb ? 'Câmera não disponível neste navegador' : 'Câmera indisponível',
            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.white),
          ),
          const SizedBox(height: 6),
          const Text(
            'Use a entrada manual abaixo com o código do QR exibido na academia.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.gray),
          ),
        ],
      ),
    );
  }
}

class _ScannerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.neon.withValues(alpha: 0.6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    const inset = 40.0;
    const len = 30.0;
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2), const Radius.circular(12));
    canvas.drawRRect(r, paint);
    final corner = Paint()..color = AppColors.neon..strokeWidth = 4..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(inset, inset + len), const Offset(inset, inset), corner);
    canvas.drawLine(const Offset(inset, inset), Offset(inset + len, inset), corner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
