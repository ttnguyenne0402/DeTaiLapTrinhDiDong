import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../../core/constants/app_colors.dart';

class OpenStreetMapWidget extends StatefulWidget {
  final String address;
  final double? latitude;
  final double? longitude;

  const OpenStreetMapWidget({
    super.key,
    required this.address,
    this.latitude,
    this.longitude,
  });

  @override
  State<OpenStreetMapWidget> createState() => _OpenStreetMapWidgetState();
}

class _OpenStreetMapWidgetState extends State<OpenStreetMapWidget> {
  final MapController _mapController = MapController();
  static const LatLng _defaultCenter = LatLng(
    10.7769,
    106.7009,
  ); // Mặc định TP.HCM

  LatLng? _roomLocation;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _roomLocation = null;
    _loading = false;
  }

  @override
  void didUpdateWidget(covariant OpenStreetMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.address != widget.address ||
        oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      _loadRoomLocation();
    }
  }

  Future<void> _loadRoomLocation() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    // 1. Ưu tiên dùng tọa độ có sẵn nếu có
    if (widget.latitude != null && widget.longitude != null) {
      setState(() {
        _roomLocation = LatLng(widget.latitude!, widget.longitude!);
        _loading = false;
      });
      return;
    }

    // 2. Kiểm tra nếu địa chỉ trống
    if (widget.address.trim().isEmpty) {
      setState(() {
        _roomLocation = null;
        _loading = false;
        _errorMessage = 'Phòng chưa có địa chỉ để xác định vị trí.';
      });
      return;
    }

    // 3. Gọi Nominatim API tìm tọa độ từ tên đường/địa chỉ
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': widget.address,
        'format': 'jsonv2',
        'limit': '1',
        'countrycodes': 'vn',
      });

      final response = await http
          .get(uri, headers: {'User-Agent': 'TroOiRentalApp/1.0'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Không thể kết nối đến dịch vụ bản đồ.');
      }

      final List results = jsonDecode(response.body);

      if (results.isEmpty) {
        setState(() {
          _roomLocation = null;
          _loading = false;
          _errorMessage = 'Không tìm thấy vị trí phù hợp với địa chỉ này.';
        });
        return;
      }

      final item = results.first;
      final location = LatLng(
        double.parse(item['lat'].toString()),
        double.parse(item['lon'].toString()),
      );

      if (!mounted) return;
      setState(() {
        _roomLocation = location;
        _loading = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;

      debugPrint('Lỗi tìm tọa độ phòng: $e');

      setState(() {
        _roomLocation = null;
        _loading = false;
        _errorMessage =
            'Không xác định được vị trí phòng. '
            'Em thử kiểm tra địa chỉ hoặc tải lại nhé.';
      });
    } catch (e, stackTrace) {
      debugPrint('Lỗi không xác định khi tìm vị trí: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _roomLocation = null;
        _loading = false;
        _errorMessage = 'Đã xảy ra lỗi khi xác định vị trí phòng.';
      });
    }
  }

  Future<void> _openGoogleMaps() async {
    final location = _roomLocation;
    if (location == null) return;

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${location.latitude},${location.longitude}'
      '&travelmode=driving',
    );

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở được Google Maps.')),
      );
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = _roomLocation ?? _defaultCenter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 260,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: LatLng(10.7769, 106.7009),
                initialZoom: 12,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.de/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.doanlaptrinhdidong',
                ),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.address,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _roomLocation == null ? null : _openGoogleMaps,
            icon: const Icon(Icons.directions),
            label: const Text('Chỉ đường bằng Google Maps'),
          ),
        ),
      ],
    );
  }
}
