import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/location_provider.dart';
import '../../models/location_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_strings.dart';
import '../../core/utils/validators.dart';

// BottomSheet for editing location
class EditLocationBottomSheet extends StatefulWidget {
  final LocationModel location;

  const EditLocationBottomSheet({super.key, required this.location});

  @override
  State<EditLocationBottomSheet> createState() =>
      _EditLocationBottomSheetState();
}

class _EditLocationBottomSheetState extends State<EditLocationBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _descriptionController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.location.name);
    _latitudeController = TextEditingController(
      text: widget.location.latitude.toStringAsFixed(6),
    );
    _longitudeController = TextEditingController(
      text: widget.location.longitude.toStringAsFixed(6),
    );
    _descriptionController = TextEditingController(
      text: widget.location.description ?? '',
    );
  }

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
                const Icon(Icons.edit_location, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  AppStrings.editLocation,
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
          SingleChildScrollView(
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
                    onPressed: _isLoading ? null : _updateLocation,
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
        ],
      ),
    );
  }

  Future<void> _updateLocation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await context.read<LocationProvider>().updateLocation(
      id: widget.location.id,
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
            content: Text(AppStrings.locationUpdated),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.locationUpdateError),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}
