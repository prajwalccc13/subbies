import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatters
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:subbies/models/subscription.dart';
import 'package:subbies/state/subscriptions_controller.dart';
import 'package:subbies/theme/app_theme.dart';
import 'package:subbies/utils/money.dart';
import 'package:subbies/widgets/monogram.dart';


class EditSubscriptionScreen extends StatefulWidget {
  const EditSubscriptionScreen({super.key, this.existing});

  /// The subscription being edited, or null when adding a new one.
  final Subscription? existing;

  @override
  State<EditSubscriptionScreen> createState() => _EditSubscriptionScreenState();
}

class _EditSubscriptionScreenState extends State<EditSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();

  // Every field gets a starting value immediately, so there is never a
  // moment where one is "empty". No `late` needed, no way to forget.
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  // Defaults for a NEW subscription.
  BillingCycle _cycle = BillingCycle.monthly;
  SubscriptionCategory _category = SubscriptionCategory.entertainment;
  DateTime _startDate = DateTime.now();
  bool _isFreeTrial = false;
  bool _isPaused = false;

  bool get _isEditing => widget.existing != null;
  
  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.name;
      _priceController.text = (existing.priceCents / 100).toStringAsFixed(2);
      _cycle = existing.cycle;
      _category = existing.category;
      _startDate = existing.startDate;
      _isFreeTrial = existing.isFreeTrial;
      _isPaused = existing.isPaused; 
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) setState(() => _startDate = picked);
  }

  void _setFreeTrial(bool value) {
    setState(() {
      _isFreeTrial = value;
       // Trials end in the future. If the date is still today (or earlier),
      // move it a week ahead as a sensible starting point the user can
      // adjust. A small touch that saves a tap.
      if (value && !_startDate.isAfter(DateTime.now())) {
        _startDate = DateTime.now().add(const Duration(days: 7));
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final subscription = Subscription(
      id: widget.existing?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      priceCents: parseCents(_priceController.text)!,
      cycle: _cycle,
      category: _category,
      startDate: DateUtils.dateOnly(_startDate), // Drop the time of day
      isFreeTrial: _isFreeTrial,
      isPaused: _isPaused,
    );

    final controller = context.read<SubscriptionsController>();
    final navigator = Navigator.of(context);

    await controller.save(subscription);
    navigator.pop();

  }

  Future<void> _delete() async {
    final existing = widget.existing!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${existing.name}?'),
        content: const Text('It will be removed from your list and totals.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            // Red for a destructive action, taken from the theme.
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final controller = context.read<SubscriptionsController>();
    Navigator.of(context).pop();
    await controller.delete(existing);

  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final preview = ListenableBuilder(
      listenable: _nameController,
      builder: (context, child) => Monogram(
        name: _nameController.text,
        color: _category.color,
        size: 72,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit subscription' : 'New subscription'),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _delete,
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),

      // Body
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Center(
                child: _isEditing
                  ? Hero(tag: 'monogram-${widget.existing!.id}', child: preview)
                  : preview,
              ),
              const SizedBox(height: 28),

              // Name Field
              const _FieldLabel('Name'),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                // The keyboard shows "next" and jumps to the price field.
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'e.g. Spotify'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Give it a name'
                    : null,
              ),
              const SizedBox(height: 20),

              // Price Field
              const _FieldLabel('Price'),
              TextFormField(
                controller: _priceController,
                // A number keyboard that includes a decimal point.
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                // INPUT FORMATTER: blocks bad typing as it happens.
                // This pattern (a "regular expression") allows digits, then
                // optionally one dot and up to 2 more digits: 9, 9.9, 9.99.
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: '$currencySymbol ', // Shows "$ " inside the box
                ),
                validator: (value) {
                  final cents = parseCents(value ?? '');
                  if (cents == null || cents <= 0) {
                    return 'Enter a price, like 9.99';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // Billing Cycle Field
              const _FieldLabel('Billed'),
              SegmentedButton<BillingCycle>(
                showSelectedIcon: false,
                segments: [
                  for (final cycle in BillingCycle.values)
                    ButtonSegment(value: cycle, label: Text(cycle.label)),
                ],
                selected: {_cycle},
                onSelectionChanged: (selection) =>
                    setState(() => _cycle = selection.first),
              ),
              const SizedBox(height: 20),
              
              // Category Field
              const _FieldLabel('Category'),
              Wrap(
                spacing: 8, 
                runSpacing: 8,
                children: [
                  for (final category in SubscriptionCategory.values)
                    // ChoiceChip = a small pill you can select.
                    ChoiceChip(
                      label: Text(category.label),
                      avatar: Icon(Icons.circle, size: 10, color: category.color),
                      showCheckmark: false,
                      selected: category == _category,
                      onSelected: (_) => setState(() => _category = category),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Status section
              const _FieldLabel('Status'),
              Material(
                color: colors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Free Trail'),
                      subtitle: const Text('Nothing is charged until it ends.'),
                      value: _isFreeTrial,
                      onChanged: _setFreeTrial,
                    ),
                    const Divider(indent: 16, endIndent: 16),
                    SwitchListTile(
                      title: const Text('Paused'),
                      subtitle: const Text('Left out of your totals for now.'),
                      value: _isPaused,
                      onChanged: (value) => setState(() => _isPaused = value),
                    ),
                  ],
                ),
              ),

              _FieldLabel(_isFreeTrial ? 'Trial ends on' : 'First charged on'),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: Icon(
                  _isFreeTrial
                    ? Icons.hourglass_bottom_rounded
                    : Icons.event_outlined,
                ),
                label: Text(DateFormat('d MMMM y').format(_startDate)),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  minimumSize: const Size.fromHeight(54),
                  foregroundColor: colors.onSurface,
                  backgroundColor: colors.surfaceContainerLowest,
                  side: BorderSide(color: colors.outlineVariant),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Text(
                _isFreeTrial
                    ? 'first payment on this date unless you cancel.'
                    : 'Used to work out when it renews next.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 32),

              FilledButton(
                onPressed: _save,
                child: Text(_isEditing ? 'Save changes' : 'Add subscription'),
              ),

            ],
          ),
        ),
      ),
    );
  }
}


class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}