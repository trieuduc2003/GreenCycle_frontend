import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String token;
  final int orderId;
  final double pickupLatitude;
  final double pickupLongitude;
  
  const LiveTrackingScreen({
    super.key,
    required this.token,
    required this.orderId,
    required this.pickupLatitude,
    required this.pickupLongitude,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final MapController _mapController = MapController();
  HubConnection? _hubConnection;
  
  LatLng? _collectorLocation;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initSignalR();
  }

  Future<void> _initSignalR() async {
    _hubConnection = HubConnectionBuilder()
        .withUrl(
          ApiEndpoints.transactionHub,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => widget.token,
          ),
        )
        .withAutomaticReconnect()
        .build();

    _hubConnection?.on("CollectorLocationUpdated", _handleLocationUpdate);

    try {
      await _hubConnection?.start();
      if (mounted) {
        setState(() {
          _isConnected = true;
        });
      }
    } catch (e) {
      print('Error connecting to SignalR for Live Tracking: $e');
    }
  }

  void _handleLocationUpdate(List<dynamic>? parameters) {
    if (parameters != null && parameters.isNotEmpty) {
      final data = parameters[0] as Map<String, dynamic>;
      
      final incomingOrderId = data['orderId'] ?? data['OrderId'];
      if (incomingOrderId == widget.orderId) {
        final lat = (data['latitude'] ?? data['Latitude'] as num).toDouble();
        final lng = (data['longitude'] ?? data['Longitude'] as num).toDouble();
        
        if (mounted) {
          setState(() {
            _collectorLocation = LatLng(lat, lng);
          });
          // Optionally center map on collector
          _mapController.move(_collectorLocation!, _mapController.camera.zoom);
        }
      }
    }
  }

  @override
  void dispose() {
    _hubConnection?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pickupLocation = LatLng(widget.pickupLatitude, widget.pickupLongitude);
    
    // Bounds for both pickup and collector (if available)
    final center = _collectorLocation ?? pickupLocation;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theo dõi tài xế', style: TextStyle(color: Color(0xFF1A2E22), fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A2E22)),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.greencycle',
              ),
              MarkerLayer(
                markers: [
                  // Pickup location (Seller)
                  Marker(
                    width: 40.0,
                    height: 40.0,
                    point: pickupLocation,
                    child: const Icon(Icons.location_on, color: Colors.redAccent, size: 36.0),
                  ),
                  // Collector location
                  if (_collectorLocation != null)
                    Marker(
                      width: 48.0,
                      height: 48.0,
                      point: _collectorLocation!,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                        ),
                        child: const Icon(Icons.local_shipping, color: AppColors.primaryGreen, size: 28.0),
                      ),
                    ),
                ],
              ),
              if (_collectorLocation != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_collectorLocation!, pickupLocation],
                      color: AppColors.primaryGreen.withOpacity(0.7),
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
            ],
          ),
          
          // Connection status overlay
          if (!_isConnected)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange.shade800)),
                    const SizedBox(width: 8),
                    Text('Đang kết nối tín hiệu...', style: TextStyle(color: Colors.orange.shade800, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            
          // Floating panel at the bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 8))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.support_agent_rounded, color: AppColors.primaryGreen),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Tài xế đang đến', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A2E22))),
                        SizedBox(height: 4),
                        Text('Vui lòng chuẩn bị rác đã phân loại', style: TextStyle(fontSize: 13, color: Color(0xFF7A8B80))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
