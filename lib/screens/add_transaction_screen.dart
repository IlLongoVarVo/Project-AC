import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/friend.dart';
import '../models/transaction.dart';

class AddTransactionScreen extends StatefulWidget {
  final Friend friend;

  const AddTransactionScreen({super.key, required this.friend});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  TransactionType _selectedType = TransactionType.credit;
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  final _dateFormat = DateFormat('d MMMM yyyy', 'it_IT');

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transazione con ${widget.friend.name}'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _TypeSelector(
              selected: _selectedType,
              onChanged: (t) => setState(() => _selectedType = t),
            ),
            const SizedBox(height: 24),
            _buildAmountField(),
            const SizedBox(height: 16),
            _buildDescriptionField(),
            const SizedBox(height: 16),
            _buildDatePicker(context),
            const SizedBox(height: 32),
            _buildSaveButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+[,.]?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: 'Importo',
        prefixText: '€ ',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Inserisci un importo';
        final amount =
            double.tryParse(value.replaceAll(',', '.'));
        if (amount == null || amount <= 0) return 'Importo non valido';
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLength: 100,
      decoration: InputDecoration(
        labelText: 'Descrizione (opzionale)',
        hintText: 'Es. Cena, benzina, biglietti...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      onTap: () => _pickDate(context),
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Data',
          suffixIcon: const Icon(Icons.calendar_today_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
        child: Text(_dateFormat.format(_selectedDate)),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    final isCredit = _selectedType == TransactionType.credit;
    final color = isCredit ? Colors.green : Colors.red;
    return FilledButton.icon(
      onPressed: _saving ? null : () => _save(context),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: _saving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward),
      label: Text(isCredit
          ? '${widget.friend.name} mi deve'
          : 'Devo a ${widget.friend.name}'),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('it', 'IT'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final amount =
        double.parse(_amountController.text.replaceAll(',', '.'));
    await context.read<AppProvider>().addTransaction(
          friendId: widget.friend.id,
          amount: amount,
          type: _selectedType,
          description: _descriptionController.text.trim(),
          date: _selectedDate,
        );
    if (context.mounted) Navigator.pop(context);
  }
}

class _TypeSelector extends StatelessWidget {
  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;

  const _TypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tipo di transazione',
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: Colors.grey.shade600)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _TypeCard(
                label: 'Mi deve',
                subtitle: 'Lui/lei è in debito',
                icon: Icons.arrow_circle_down_outlined,
                color: Colors.green,
                selected: selected == TransactionType.credit,
                onTap: () => onChanged(TransactionType.credit),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TypeCard(
                label: 'Devo io',
                subtitle: 'Io sono in debito',
                icon: Icons.arrow_circle_up_outlined,
                color: Colors.red,
                selected: selected == TransactionType.debt,
                onTap: () => onChanged(TransactionType.debt),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? color : Colors.grey.shade400, size: 32),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selected ? color : Colors.grey.shade600,
                    fontSize: 14)),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 11,
                    color: selected ? color : Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }
}
