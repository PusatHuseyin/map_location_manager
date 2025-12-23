import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/location_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_strings.dart';
import '../../core/utils/validators.dart';
import '../../widgets/map_location_picker.dart';

// BottomSheet for adding new location
class AddLocationBottomSheet extends StatefulWidget {
  const AddLocationBottomSheet({super.key});

  @override
  State<AddLocationBottomSheet> createState() => _AddLocationBottomSheetState();
}

class _AddLocationBottomSheetState extends State<AddLocationBottomSheet> {
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.add_location, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  AppStrings.addLocation,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: AppStrings.locationName,
                        hintText: AppStrings.locationNameHint,
                        prefixIcon: const Icon(Icons.label),
                      ),
                      validator: (value) =>
                          Validators.required(value, AppStrings.locationName),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      value: _useCurrentLocation,
                      onChanged: (value) {
                        setState(() => _useCurrentLocation = value ?? false);
                        if (_useCurrentLocation) _fillCurrentLocation();
                      },
                      title: Text(AppStrings.useCurrentLocation),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _useCurrentLocation ? null : _pickFromMap,
                      icon: const Icon(Icons.map),
                      label: const Text('Haritadan Seç'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _latitudeController,
                      decoration: InputDecoration(
                        labelText: AppStrings.latitude,
                        hintText: '37.8746',
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      enabled: !_useCurrentLocation,
                      validator: Validators.latitude,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _longitudeController,
                      decoration: InputDecoration(
                        labelText: AppStrings.longitude,
                        hintText: '32.4932',
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      enabled: !_useCurrentLocation,
                      validator: Validators.longitude,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: '${AppStrings.description} (Opsiyonel)',
                        hintText: AppStrings.descriptionHint,
                        prefixIcon: const Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveLocation,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(AppStrings.save),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
          SnackBar(
            content: Text(AppStrings.currentLocationError),
            backgroundColor: AppTheme.error,
          ),
        );
      }
      setState(() => _useCurrentLocation = false);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _pickFromMap() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (context) => const MapLocationPicker()),
    );

    if (result != null) {
      _latitudeController.text = result.latitude.toStringAsFixed(6);
      _longitudeController.text = result.longitude.toStringAsFixed(6);
    }
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
          SnackBar(
            content: Text(AppStrings.locationAdded),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.locationAddError),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}
