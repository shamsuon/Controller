import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/bluetooth_service.dart';
import '../services/database_service.dart';
import '../models/device_model.dart';
import '../utils/error_handler.dart';
import '../widgets/discovery_dialog.dart';
import '../widgets/add_device_form.dart';
import '../widgets/dynamic_device_card.dart';
import '../services/last_device_storage.dart';
import 'package:provider/provider.dart';

import '../models/device_state_manager.dart';
import '../widgets/rack_device_card.dart';
import '../widgets/rfid_door_lock_card.dart';
import '../widgets/auto_lock_door_card.dart';
import '../widgets/notification_center.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isAutoReconnecting = false;
  static bool _autoReconnectTried = false;
  final BluetoothService _bluetoothService = BluetoothService();
  final DatabaseService _databaseService = DatabaseService();

  late AnimationController _bgAnimationController;
  late AnimationController _gridAnimationController;
  late AnimationController _tabCardsAnimationController;
  late PageController _tabsPageController;
  late ScrollController _tabsScrollController;

  // App State
  String? _selectedDeviceName;
  String _btAddress = "";
  bool _isBluetoothMode = true;
  int _selectedTabIndex = 0;

  List<SmartDeviceDB> _allDevices = [];
  bool _isLoadingDevices = false;

  StreamSubscription? _btStateSubscription;

  final List<String> _tabs = [
    'Favorites',
    'Lights',
    'Doors',
    'Fans',
    'Tools',
    'Climate',
    'Security',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _setupBluetoothListeners();
    _initAppStartup();
  }

  Future<void> _initAppStartup() async {
    // Ensure permissions and Bluetooth mode are enabled before reconnect
    if (!_isBluetoothMode) return;
    if (!await _checkPermissions()) return;
    await _loadDevicesAndReconnect();
  }

  Future<void> _loadDevicesAndReconnect() async {
    setState(() => _isLoadingDevices = true);
    try {
      final devices = await _databaseService.getAllDevices();
      final stateManager = Provider.of<DeviceStateManager>(
        context,
        listen: false,
      );

      if (mounted) {
        for (var device in devices) {
          // Check if device already exists in manager to preserve current UI state
          final existingState = stateManager.getDevice(device.id);

          stateManager.addOrUpdateDevice(
            device,
            DeviceState(
              id: device.id,
              name: device.name,
              isOn: existingState?.isOn ?? device.isOn,
              isFavorite: existingState?.isFavorite ?? device.isFavorite,
              rackAngle: existingState?.rackAngle ?? device.lastAngle,
              rfidLastMessage: existingState?.rfidLastMessage ?? device.rfidLastMessage,
            ),
          );
        }
        setState(() {
          _allDevices = devices;
        });
        await _tryAutoReconnect();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error loading devices: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingDevices = false);
      }
    }
  }

  Future<void> _tryAutoReconnect() async {
    if (_autoReconnectTried || _bluetoothService.isConnected) return;
    _autoReconnectTried = true;
    final lastAddress = await LastDeviceStorage.getAddress();
    if (lastAddress != null && lastAddress.isNotEmpty) {
      setState(() => _isAutoReconnecting = true);
      _selectedDeviceName = null;
      _btAddress = lastAddress;
      try {
        await _bluetoothService.connect(lastAddress);
        if (_bluetoothService.isConnected) {
          setState(() => _isAutoReconnecting = false);
        } else {
          setState(() => _isAutoReconnecting = false);
          _showSnackBar(
            'Auto-reconnect failed: Could not connect to last device',
            isError: true,
          );
        }
      } catch (e) {
        setState(() => _isAutoReconnecting = false);
        _showSnackBar('Auto-reconnect error: $e', isError: true);
      }
    }
  }

  void _initAnimations() {
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);

    _gridAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _tabCardsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..value = 1.0;

    _tabsPageController = PageController();
    _tabsScrollController = ScrollController();

    _tabsPageController.addListener(() {
      if (!mounted) return;
      int newIndex = (_tabsPageController.page ?? 0).round();
      if (newIndex != _selectedTabIndex) {
        setState(() {
          _selectedTabIndex = newIndex;
        });
        _scrollToTab(newIndex);
      }
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _gridAnimationController.forward();
        _tabCardsAnimationController.forward(from: 0);
      }
    });
  }

  void _setupBluetoothListeners() {
    _btStateSubscription = _bluetoothService.stateStream.listen((state) async {
      if (!mounted) return;
      setState(() {
        if (state == BluetoothStateEnum.error) {
          _showSnackBar(
            'Connection failed. Check server status.',
            isError: true,
          );
        }
        if (state == BluetoothStateEnum.connected && _btAddress.isNotEmpty) {
          LastDeviceStorage.saveAddress(_btAddress);
        }
      });
    });
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoadingDevices = true);
    try {
      final devices = await _databaseService.getAllDevices();
      final stateManager = Provider.of<DeviceStateManager>(
        context,
        listen: false,
      );
      if (mounted) {
        for (var device in devices) {
          stateManager.addOrUpdateDevice(
            device,
            DeviceState(
              id: device.id,
              name: device.name,
              isOn: device.isOn,
              isFavorite: device.isFavorite,
              rackAngle: device.lastAngle,
            ),
          );
        }
        setState(() {
          _allDevices = devices;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error loading devices: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingDevices = false);
      }
    }
  }

  void _showAddDeviceForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddDeviceBottomSheet(
        onDeviceAdded: () {
          _loadDevices();
        },
      ),
    );
  }

  Future<void> _reorderDevices(
    int oldIndex,
    int newIndex,
    List<SmartDeviceDB> currentTabDevices,
  ) async {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final device = currentTabDevices.removeAt(oldIndex);
      currentTabDevices.insert(newIndex, device);
    });

    // Persist new order for this tab to database
    for (int i = 0; i < currentTabDevices.length; i++) {
      currentTabDevices[i].order = i;
    }
    await _databaseService.reorderDevices(currentTabDevices);
  }

  Future<bool> _checkPermissions() async {
    // Request all relevant permissions for Android 12+
    final permissions = [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ];

    Map<Permission, PermissionStatus> statuses = await permissions.request();

    bool allGranted = permissions.every(
      (perm) => statuses[perm]?.isGranted ?? false,
    );

    if (!allGranted && mounted) {
      String denied = permissions
          .where((perm) => !(statuses[perm]?.isGranted ?? false))
          .map((perm) => perm.toString().split('.').last)
          .join(', ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Bluetooth permission required: $denied"),
          backgroundColor: Colors.redAccent,
        ),
      );
      // Optionally open app settings if permanently denied
      if (permissions.any(
        (perm) => statuses[perm]?.isPermanentlyDenied ?? false,
      )) {
        await Future.delayed(const Duration(seconds: 1));
        openAppSettings();
      }
    }
    return allGranted;
  }

  Future<void> _showDiscoveryDialog() async {
    if (!_isBluetoothMode) {
      _showSnackBar('Bluetooth mode is off', isError: true);
      return;
    }
    if (!await _checkPermissions()) return;

    final result = await showGeneralDialog<DiscoveryResult>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'DiscoveryDialog',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return const DiscoveryDialog();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: CurvedAnimation(
            parent: anim1,
            curve: Curves.easeOutBack,
          ).value,
          child: FadeTransition(
            opacity: CurvedAnimation(parent: anim1, curve: Curves.easeInOut),
            child: child,
          ),
        );
      },
    );

    if (result != null && result.device != null) {
      setState(() {
        _btAddress = result.device!.address;
        _selectedDeviceName = result.device!.name;
      });
      _showSnackBar(
        'Selected: ${result.device!.name ?? result.device!.address}',
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    BluetoothErrorHandler.showGlassySnackBar(
      context,
      message,
      isError: isError,
    );
  }

  void _scrollToTab(int index) {
    if (!_tabsScrollController.hasClients) return;

    // Calculate target offset to center the tab
    // Average tab width is about 100px.
    // This is a simple approximation; better would be giving each tab a global key.
    const double approxTabWidth = 100.0;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double targetOffset =
        (index * approxTabWidth) - (screenWidth / 2) + (approxTabWidth / 2);

    _tabsScrollController.animateTo(
      targetOffset.clamp(0, _tabsScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    _gridAnimationController.dispose();
    _tabCardsAnimationController.dispose();
    _tabsPageController.dispose();
    _tabsScrollController.dispose();

    _btStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isConnected = _bluetoothService.isConnected;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isConnected),
            Expanded(child: _buildTabsAndContent(isConnected)),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _showAddDeviceForm,
      backgroundColor: Colors.cyanAccent,
      foregroundColor: Colors.black87,
      child: const Icon(Icons.add_rounded, size: 28),
    );
  }

  Widget _buildHeader(bool isConnected) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: Logo + Title (shrinks to fit content)
                Flexible(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Transform.scale(
                          scale: 1.15,
                          child: Image.asset(
                            'assets/images/controller_logo_square.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Smart Home',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w900,
                                fontSize: 24,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Control Panel',
                              style: TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 12,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Right: NotificationCenter + Bluetooth (fixed width)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Notification Center
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: NotificationCenter(),
                    ),
                    // Bluetooth Toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.0,
                        ),
                        boxShadow: [
                          if (_isBluetoothMode)
                            BoxShadow(
                              color: Colors.cyanAccent.withOpacity(0.2),
                              blurRadius: 15,
                            ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.bluetooth,
                              size: 16,
                              color: _isBluetoothMode
                                  ? Colors.cyanAccent
                                  : Colors.white60,
                            ),
                          ),
                          Transform.scale(
                            scale: 0.7,
                            child: Switch(
                              value: _isBluetoothMode,
                              activeColor: Colors.cyanAccent,
                              onChanged: (value) async {
                                setState(() {
                                  _isBluetoothMode = value;
                                  if (value) _autoReconnectTried = false;
                                });
                                if (!value) {
                                  await _bluetoothService.disconnect();
                                  _showSnackBar('Bluetooth Mode Disabled');
                                } else {
                                  await _tryAutoReconnect();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildConnectionBar(isConnected),
          const SizedBox(height: 12),
          _buildTabButtons(),
        ],
      ),
    );
  }

  Widget _buildConnectionBar(bool isConnected) {
    if (_isAutoReconnecting) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.cyanAccent),
              strokeWidth: 2.5,
            ),
            const SizedBox(width: 16),
            const Text(
              'Reconnecting to last device...',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }
    Color color;
    String text;
    IconData icon;
    switch (_bluetoothService.currentState) {
      case BluetoothStateEnum.connected:
        color = Colors.greenAccent;
        text = "Connected";
        icon = Icons.bluetooth_connected;
        break;
      case BluetoothStateEnum.connecting:
        color = Colors.orangeAccent;
        text = "Connecting...";
        icon = Icons.bluetooth_searching;
        break;
      case BluetoothStateEnum.error:
        color = Colors.redAccent;
        text = "Connection Error";
        icon = Icons.error_outline;
        break;
      default:
        color = Colors.white24;
        text = "Disconnected";
        icon = Icons.bluetooth_disabled;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _selectedDeviceName ??
                      (_btAddress.isNotEmpty
                          ? _btAddress
                          : "No device selected"),
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isBluetoothMode ? _showDiscoveryDialog : () {},
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isBluetoothMode
                      ? Colors.white.withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isBluetoothMode
                        ? Colors.white.withOpacity(0.4)
                        : Colors.white.withOpacity(0.15),
                  ),
                ),
                child: Icon(
                  Icons.search,
                  color: _isBluetoothMode ? Colors.white : Colors.white30,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButtons() {
    return SingleChildScrollView(
      controller: _tabsScrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isActive = _selectedTabIndex == index;
          return Padding(
            padding: EdgeInsets.only(right: index == _tabs.length - 1 ? 0 : 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _tabsPageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withOpacity(0.25)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? Colors.white.withOpacity(0.5)
                          : Colors.transparent,
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    _tabs[index],
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white70,
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabsAndContent(bool isConnected) {
    return PageView(
      controller: _tabsPageController,
      onPageChanged: (index) {
        setState(() => _selectedTabIndex = index);
        _tabCardsAnimationController.forward(from: 0);
      },
      children: List.generate(_tabs.length, (index) {
        return Consumer<DeviceStateManager>(
          builder: (context, deviceStateManager, _) {
            return TabContent(
              tabName: _tabs[index],
              allDevices: _allDevices,
              isLoadingDevices: _isLoadingDevices,
              isConnected: isConnected,
              onReorder: _reorderDevices,
              onDelete: _loadDevices,
            );
          },
        );
      }),
    );
  }
} // End of _HomeScreenState

class TabContent extends StatefulWidget {
  final String tabName;
  final List<SmartDeviceDB> allDevices;
  final bool isLoadingDevices;
  final bool isConnected;
  final Function(int, int, List<SmartDeviceDB>) onReorder;
  final VoidCallback onDelete;

  const TabContent({
    Key? key,
    required this.tabName,
    required this.allDevices,
    required this.isLoadingDevices,
    required this.isConnected,
    required this.onReorder,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<TabContent> createState() => _TabContentState();
}

class _TabContentState extends State<TabContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    if (widget.isLoadingDevices) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Colors.cyanAccent),
        ),
      );
    }

    final stateManager = Provider.of<DeviceStateManager>(context);
    final currentTabDevices = widget.tabName == 'Favorites'
        ? widget.allDevices.where((d) {
            final state = stateManager.getDevice(d.id);
            return state?.isFavorite ?? d.isFavorite;
          }).toList()
        : widget.allDevices.where((d) => d.tab == widget.tabName).toList();

    currentTabDevices.sort((a, b) => a.order.compareTo(b.order));

    if (currentTabDevices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.tabName == 'Favorites'
                  ? Icons.star_border_rounded
                  : Icons.devices_other_rounded,
              color: Colors.white24,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              widget.tabName == 'Favorites'
                  ? 'No favorite devices yet.\nTap the star icon on any card.'
                  : 'No devices in this tab.\nTap + to add one.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ReorderableListView(
      onReorder: (oldIndex, newIndex) =>
          widget.onReorder(oldIndex, newIndex, currentTabDevices),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: currentTabDevices.map((device) {
        final modelLower = device.model.toLowerCase();
        final isRack = modelLower.contains('rack');
        final isRfidDoor = modelLower.contains('rfid door');
        final isAutoLock = modelLower.contains('auto lock');

        return Padding(
          key: ValueKey(device.id),
          padding: const EdgeInsets.only(bottom: 12),
          child: isRack
              ? RackDeviceCard(
                  device: device,
                  isConnected: widget.isConnected,
                  onFavoriteToggled: () => setState(() {}),
                  onDelete: widget.onDelete,
                )
              : isRfidDoor
              ? RfidDoorLockCard(
                  device: device,
                  isConnected: widget.isConnected,
                  onFavoriteToggled: () => setState(() {}),
                  onDelete: widget.onDelete,
                )
              : isAutoLock
              ? AutoLockDoorCard(
                  device: device,
                  isConnected: widget.isConnected,
                  onFavoriteToggled: () => setState(() {}),
                  onDelete: widget.onDelete,
                )
              : DynamicDeviceCard(
                  device: device,
                  isConnected: widget.isConnected,
                  onFavoriteToggled: () => setState(() {}),
                  onDelete: widget.onDelete,
                ),
        );
      }).toList(),
    );
  }
}
