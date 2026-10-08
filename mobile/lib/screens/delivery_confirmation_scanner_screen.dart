import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/order_service.dart';

class DeliveryConfirmationScannerScreen extends StatefulWidget {
  const DeliveryConfirmationScannerScreen({
    super.key,
  });

  @override
  State<DeliveryConfirmationScannerScreen> createState() =>
      _DeliveryConfirmationScannerScreenState();
}

class _DeliveryConfirmationScannerScreenState
    extends State<DeliveryConfirmationScannerScreen> {
  final MobileScannerController _scannerController =
      MobileScannerController();

  bool _isProcessing = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleQrCode(String value) async {
    if (_isProcessing) return;

    final token = _extractToken(value);

    if (token == null || token.isEmpty) {
      _showMessage(
        'Invalid delivery confirmation QR code.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    await _scannerController.stop();

    try {
      final result =
          await OrderService.getDeliveryConfirmation(token);

      if (!mounted) return;

      await _showConfirmationDialog(
        token: token,
        data: result,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        _cleanError(e),
        isError: true,
      );

      setState(() {
        _isProcessing = false;
      });

      await _scannerController.start();
    }
  }

  String? _extractToken(String value) {
    final cleaned = value.trim();

    if (cleaned.isEmpty) {
      return null;
    }

    // Backend normally generates:
    // /delivery-confirmation/<token>
    try {
      final uri = Uri.tryParse(cleaned);

      if (uri != null && uri.pathSegments.isNotEmpty) {
        final segments = uri.pathSegments;

        final confirmationIndex =
            segments.indexOf('delivery-confirmation');

        if (confirmationIndex >= 0 &&
            confirmationIndex + 1 < segments.length) {
          return segments[confirmationIndex + 1];
        }
      }
    } catch (_) {
      // Continue and treat the QR value as a raw token.
    }

    // Also allow a QR containing only the token.
    if (!cleaned.contains('/') &&
        !cleaned.contains('://')) {
      return cleaned;
    }

    return null;
  }

  Future<void> _showConfirmationDialog({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    final orderId = data['order_id'];
    final totalAmount = data['total_amount'];
    final paymentMethod =
        data['payment_method']?.toString() ?? '';
    final paymentStatus =
        data['payment_status']?.toString() ?? '';
    final orderStatus =
        data['order_status']?.toString() ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.qr_code_scanner,
                color: Colors.blue,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text('Confirm Delivery'),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _infoRow(
                  'Order ID',
                  '#$orderId',
                ),
                const SizedBox(height: 10),
                _infoRow(
                  'Amount',
                  '₹$totalAmount',
                ),
                const SizedBox(height: 10),
                _infoRow(
                  'Payment',
                  paymentMethod.toUpperCase(),
                ),
                const SizedBox(height: 10),
                _infoRow(
                  'Payment Status',
                  paymentStatus,
                ),
                const SizedBox(height: 10),
                _infoRow(
                  'Order Status',
                  orderStatus,
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Confirm only after the order has been handed over to the customer.',
                    style: TextStyle(
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Confirm Delivery'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (confirmed != true) {
      setState(() {
        _isProcessing = false;
      });

      await _scannerController.start();
      return;
    }

    await _confirmDelivery(token);
  }

  Future<void> _confirmDelivery(String token) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final result =
          await OrderService.confirmDelivery(token);

      if (!mounted) return;

      final orderId = result['order_id'];
      final orderStatus =
          result['order_status']?.toString() ?? 'delivered';
      final paymentStatus =
          result['payment_status']?.toString() ?? 'paid';

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Delivery Confirmed'),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #$orderId has been successfully delivered.',
                ),
                const SizedBox(height: 14),
                _infoRow(
                  'Order Status',
                  orderStatus,
                ),
                const SizedBox(height: 10),
                _infoRow(
                  'Payment Status',
                  paymentStatus,
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      await _scannerController.start();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        _cleanError(e),
        isError: true,
      );

      setState(() {
        _isProcessing = false;
      });

      await _scannerController.start();
    }
  }

  Widget _infoRow(
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  String _cleanError(Object error) {
    final message = error
        .toString()
        .replaceFirst('Exception: ', '')
        .trim();

    return message.isEmpty
        ? 'Unable to process the QR code.'
        : message;
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107),
        title: const Text('Scan Delivery QR'),
        actions: [
          IconButton(
            tooltip: 'Toggle flashlight',
            onPressed: _isProcessing
                ? null
                : () async {
                    await _scannerController.toggleTorch();

                    if (!mounted) return;

                    setState(() {
                      _torchOn = !_torchOn;
                    });
                  },
            icon: Icon(
              _torchOn
                  ? Icons.flash_on
                  : Icons.flash_off,
            ),
          ),
          IconButton(
            tooltip: 'Switch camera',
            onPressed: _isProcessing
                ? null
                : () {
                    _scannerController.switchCamera();
                  },
            icon: const Icon(
              Icons.cameraswitch,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              if (_isProcessing) return;

              if (capture.barcodes.isEmpty) {
                return;
              }

              final rawValue =
                  capture.barcodes.first.rawValue;

              if (rawValue == null ||
                  rawValue.trim().isEmpty) {
                return;
              }

              _handleQrCode(rawValue);
            },
          ),

          Center(
            child: Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                borderRadius:
                    BorderRadius.circular(20),
              ),
            ),
          ),

          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(
                  alpha: 0.70,
                ),
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  const Text(
                    'Scan the customer delivery QR code',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isProcessing
                        ? 'Processing...'
                        : 'Place the QR code inside the frame.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_isProcessing)
            Container(
              color: Colors.black.withValues(
                alpha: 0.35,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}