import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/location_provider.dart';
import '../../core/theme/app_theme.dart';

class AddLocationDialog extends StatefulWidget {
  const AddLocationDialog({super.key});

  @override
  State<AddLocationDialog> createState() => _AddLocationDialogState();
}

class _AddLocationDialogState extends State<AddLocationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _useCurrentLocation = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni Konum Ekle'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Konum Adi',
                  hintText: 'Ornek: Evim, Isyeri',
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Konum adi gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _useCurrentLocation,
                    onChanged: (value) {
                      setState(() {
                        _useCurrentLocation = value ?? false;
                      });
                      if (_useCurrentLocation) {
                        _fillCurrentLocation();
                      }
                    },
                  ),
                  const Text('Mevcut konumumu kullan'),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _latitudeController,
                decoration: const InputDecoration(
                  labelText: 'Enlem (Latitude)',
                  hintText: '37.8746',
                  prefixIcon: Icon(Icons.location_on),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                enabled: !_useCurrentLocation,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enlem gerekli';
                  }
                  final lat = double.tryParse(value);
                  if (lat == null || lat < -90 || lat > 90) {
                    return 'Gecerli bir enlem girin (-90 ile 90 arasi)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _longitudeController,
                decoration: const InputDecoration(
                  labelText: 'Boylam (Longitude)',
                  hintText: '32.4932',
                  prefixIcon: Icon(Icons.location_on),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                enabled: !_useCurrentLocation,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Boylam gerekli';
                  }
                  final lng = double.tryParse(value);
                  if (lng == null || lng < -180 || lng > 180) {
                    return 'Gecerli bir boylam girin (-180 ile 180 arasi)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Aciklama (Opsiyonel)',
                  hintText: 'Konum hakkinda notlar',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Iptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveLocation,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Kaydet'),
        ),
      ],
    );
  }

  Future<void> _fillCurrentLocation() async {
    setState(() => _isLoading = true);

    final provider = context.read<LocationProvider>();
    await provider.updateCurrentPosition();

    final position = provider.currentPosition;
    if (position != null) {
      _latitudeController.text = position.latitude.toStringAsFixed(6);
      _longitudeController.text = position.longitude.toStringAsFixed(6);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mevcut konum alinamadi. Izinleri kontrol edin.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
      setState(() => _useCurrentLocation = false);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveLocation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await context.read<LocationProvider>().addLocation(
          name: _nameController.text.trim(),
          latitude: double.parse(_latitudeController.text),
          longitude: double.parse(_longitudeController.text),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konum basariyla eklendi'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konum eklenirken hata olustu'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}
