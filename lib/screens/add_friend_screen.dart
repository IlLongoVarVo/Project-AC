import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  Color _selectedColor = const Color(0xFF5C6BC0);
  bool _saving = false;

  static const _avatarColors = [
    Color(0xFF5C6BC0), // indigo
    Color(0xFF42A5F5), // blue
    Color(0xFF26A69A), // teal
    Color(0xFF66BB6A), // green
    Color(0xFFFFA726), // orange
    Color(0xFFEF5350), // red
    Color(0xFFAB47BC), // purple
    Color(0xFF78909C), // blue-grey
    Color(0xFFEC407A), // pink
    Color(0xFF8D6E63), // brown
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aggiungi amico'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: _buildAvatarPreview()),
            const SizedBox(height: 24),
            _buildNameField(),
            const SizedBox(height: 24),
            _buildColorPicker(),
            const SizedBox(height: 32),
            _buildSaveButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPreview() {
    final initials = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : '?';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: _selectedColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: _selectedColor.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      alignment: Alignment.center,
      child: Text(initials,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      textCapitalization: TextCapitalization.words,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: 'Nome',
        hintText: 'Es. Mario Rossi',
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Inserisci un nome';
        if (value.trim().length < 2) return 'Il nome è troppo corto';
        return null;
      },
    );
  }

  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Colore avatar',
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: Colors.grey.shade600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _avatarColors.map((color) {
            final isSelected = _selectedColor.toARGB32() == color.toARGB32();
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 3)
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 8)
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 22)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return FilledButton.icon(
      onPressed: _saving ? null : () => _save(context),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: _saving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.check),
      label: const Text('Salva'),
    );
  }

  Future<void> _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await context
        .read<AppProvider>()
        .addFriend(_nameController.text, _selectedColor);
    if (context.mounted) Navigator.pop(context);
  }
}
