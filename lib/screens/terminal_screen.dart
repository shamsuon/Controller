import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/bluetooth_service.dart';
import '../utils/error_handler.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final BluetoothService _bluetoothService = BluetoothService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  StreamSubscription<TerminalEntry>? _terminalSub;
  List<TerminalEntry> _entries = [];
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    // Load existing log entries
    _entries = List.from(_bluetoothService.terminalLog);

    // Listen for new entries
    _terminalSub = _bluetoothService.terminalStream.listen((entry) {
      if (mounted) {
        setState(() => _entries.add(entry));
        if (_autoScroll) _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _terminalSub?.cancel();
    _scrollController.dispose();
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      } catch (_) {
        // Ignore transient scroll errors (e.g. detaching during route/tab changes).
      }
    });
  }

  Future<void> _sendManualCommand() async {
    final cmd = _inputController.text.trim();
    if (cmd.isEmpty) return;
    if (!_bluetoothService.isConnected) {
      BluetoothErrorHandler.showGlassySnackBar(context, 'غير متصل بجهاز');
      return;
    }
    try {
      await _bluetoothService.sendCommand(cmd, isManual: true);
      _inputController.clear();
    } catch (_) {
      if (!mounted) return;
      BluetoothErrorHandler.showGlassySnackBar(context, 'فشل إرسال الأمر');
    }
  }

  void _clearLog() {
    setState(() {
      _entries.clear();
      _bluetoothService.terminalLog.clear();
    });
  }

  void _copyAll() {
    final text = _entries
        .map(
          (e) =>
              '[${_formatTime(e.time)}] ${e.direction == TerminalDirection.tx ? "TX" : "RX"}: ${e.message}',
        )
        .join('\n');
    Clipboard.setData(ClipboardData(text: text));
    BluetoothErrorHandler.showGlassySnackBar(
      context,
      'تم النسخ إلى الحافظة',
      isError: false,
    );
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final bool isConnected = _bluetoothService.isConnected;

    // Separate entries into commands (all TX/RX) and errors (currently tracked separately)
    final commandEntries = _entries.where((e) => !e.isError).toList();
    final errorEntries = _entries.where((e) => e.isError).toList();

    return Container(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Content
          Column(
            children: [
              // Top Bar
              ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 10,
                      bottom: 16,
                      left: 16,
                      right: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                            ),
                          ),
                          child: const Icon(
                            Icons.terminal_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Terminal',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                isConnected
                                    ? 'Connected · ${commandEntries.length} commands, ${errorEntries.length} errors'
                                    : 'Disconnected',
                                style: TextStyle(
                                  color: isConnected
                                      ? Colors.cyanAccent.withOpacity(0.8)
                                      : Colors.white30,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Auto-scroll toggle
                        IconButton(
                          onPressed: () =>
                              setState(() => _autoScroll = !_autoScroll),
                          icon: Icon(
                            _autoScroll
                                ? Icons.vertical_align_bottom
                                : Icons.pause,
                            color: _autoScroll
                                ? Colors.cyanAccent
                                : Colors.white38,
                            size: 20,
                          ),
                          tooltip: _autoScroll
                              ? 'Auto-scroll ON'
                              : 'Auto-scroll OFF',
                        ),
                        IconButton(
                          onPressed: _entries.isEmpty ? null : _copyAll,
                          icon: const Icon(
                            Icons.copy_rounded,
                            color: Colors.white38,
                            size: 20,
                          ),
                          tooltip: 'Copy all',
                        ),
                        IconButton(
                          onPressed: _entries.isEmpty ? null : _clearLog,
                          icon: const Icon(
                            Icons.delete_sweep_rounded,
                            color: Colors.white38,
                            size: 20,
                          ),
                          tooltip: 'Clear',
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Two-Section Layout
              Expanded(
                child: _entries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.terminal_rounded,
                              color: Colors.white12,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isConnected
                                  ? 'No messages yet.\nSend a command or control a device.'
                                  : 'Connect to a device to see data.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white24,
                                fontSize: 14,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // Top Section (2/3): Commands & Responses
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                              ),
                              child: Column(
                                children: [
                                  // Legend
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      10,
                                      16,
                                      8,
                                    ),
                                    child: Row(
                                      children: [
                                        _legendBadge(
                                          'TX',
                                          Colors.tealAccent,
                                          'Sent',
                                        ),
                                        const SizedBox(width: 12),
                                        _legendBadge(
                                          'RX',
                                          Colors.amber,
                                          'Received',
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Commands List
                                  Expanded(
                                    child: commandEntries.isEmpty
                                        ? Center(
                                            child: Text(
                                              'No commands sent yet.',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.3,
                                                ),
                                                fontSize: 13,
                                              ),
                                            ),
                                          )
                                        : ListView.builder(
                                            controller: _scrollController,
                                            padding: const EdgeInsets.fromLTRB(
                                              16,
                                              0,
                                              16,
                                              10,
                                            ),
                                            itemCount: commandEntries.length,
                                            itemBuilder: (context, index) =>
                                                _buildEntry(
                                                  commandEntries[index],
                                                ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Bottom Section (1/3): Errors
                          Expanded(
                            flex: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                color: Colors.redAccent.withOpacity(0.02),
                              ),
                              child: Column(
                                children: [
                                  // Error Header
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      8,
                                      16,
                                      8,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent.withOpacity(
                                              0.25,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: Colors.redAccent
                                                  .withOpacity(0.5),
                                              width: 0.5,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.warning_rounded,
                                                size: 12,
                                                color: Colors.redAccent,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'ERRORS',
                                                style: TextStyle(
                                                  color: Colors.redAccent,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w900,
                                                  fontFamily: 'monospace',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          errorEntries.length.toString(),
                                          style: TextStyle(
                                            color: Colors.redAccent.withOpacity(
                                              0.7,
                                            ),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Errors List
                                  Expanded(
                                    child: errorEntries.isEmpty
                                        ? Center(
                                            child: Text(
                                              'No errors yet.',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.3,
                                                ),
                                                fontSize: 13,
                                              ),
                                            ),
                                          )
                                        : ListView.builder(
                                            padding: const EdgeInsets.fromLTRB(
                                              16,
                                              0,
                                              16,
                                              8,
                                            ),
                                            itemCount: errorEntries.length,
                                            itemBuilder: (context, index) =>
                                                _buildErrorEntry(
                                                  errorEntries[index],
                                                ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),

              // Floating WhatsApp-style Input bar
              Container(
                margin: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(
                      '> ',
                      style: TextStyle(
                        color: Colors.cyanAccent.withOpacity(0.8),
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        focusNode: _inputFocusNode,
                        controller: _inputController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type command...',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                        ),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            _sendManualCommand();
                            _inputFocusNode.requestFocus();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (_inputController.text.trim().isNotEmpty) {
                            _sendManualCommand();
                            _inputFocusNode.requestFocus();
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isConnected
                                ? Colors.cyanAccent.withOpacity(0.2)
                                : Colors.white.withOpacity(0.08),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isConnected
                                  ? Colors.cyanAccent.withOpacity(0.6)
                                  : Colors.white24,
                              width: 1.5,
                            ),
                            boxShadow: isConnected
                                ? [
                                    BoxShadow(
                                      color: Colors.cyanAccent.withOpacity(0.3),
                                      blurRadius: 15,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Icon(
                            Icons.send_rounded,
                            color: isConnected
                                ? Colors.cyanAccent
                                : Colors.white24,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEntry(TerminalEntry entry) {
    final isTx = entry.direction == TerminalDirection.tx;
    final color = isTx ? Colors.cyanAccent : Colors.amber;
    final label = isTx ? 'TX' : 'RX';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time
          Text(
            _formatTime(entry.time),
            style: const TextStyle(
              color: Colors.white24,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Message
          Expanded(
            child: Text(
              entry.message,
              style: TextStyle(
                color: color.withOpacity(0.9),
                fontSize: 13,
                fontFamily: 'monospace',
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorEntry(TerminalEntry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time
          Text(
            _formatTime(entry.time),
            style: TextStyle(
              color: Colors.redAccent.withOpacity(0.5),
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          // Error Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.redAccent.withOpacity(0.4),
                width: 0.5,
              ),
            ),
            child: const Text(
              'ERR',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Error Message
          Expanded(
            child: Text(
              entry.message,
              style: TextStyle(
                color: Colors.redAccent.withOpacity(0.85),
                fontSize: 13,
                fontFamily: 'monospace',
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendBadge(String label, Color color, String desc) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(desc, style: const TextStyle(color: Colors.white30, fontSize: 11)),
      ],
    );
  }
}
