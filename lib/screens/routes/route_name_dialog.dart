import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/route_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_strings.dart';

class RouteNameDialog extends StatefulWidget {
  const RouteNameDialog({super.key});

  @override
  State<RouteNameDialog> createState() => _RouteNameDialogState();
}

class _RouteNameDialogState extends State<RouteNameDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _nameController.text =
        'Rota ${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppStrings.saveRoute),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: AppStrings.routeName,
                hintText: AppStrings.routeNameHint,
                prefixIcon: const Icon(Icons.route),
              ),
              autofocus: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Rota adi gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Rota kaydedilecek ve takip duracak.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, null),
          child: Text(AppStrings.cancel),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveRoute,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(AppStrings.save),
        ),
      ],
    );
  }

  Future<void> _saveRoute() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final routeName = _nameController.text.trim();
    final success = await context.read<RouteProvider>().stopRouteTracking(
      customName: routeName,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context, routeName);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.routeSaved),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rota kaydedilemedi'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}
