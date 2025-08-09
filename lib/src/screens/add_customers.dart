// ignore_for_file: use_build_context_synchronously, unused_field

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddCustomer extends StatefulWidget {
  const AddCustomer({super.key});

  @override
  State<AddCustomer> createState() => _AddCustomerState();
}

class _AddCustomerState extends State<AddCustomer> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _buinessNameController = TextEditingController();

  bool _isLoading = false;
  bool _isSaved = false;
  List<dynamic> _customers = [];

  final supabase = Supabase.instance.client;

  int _currentPage = 0;
  final int _pageSize = 5;

  bool _hasFetched = false;

  @override
  void initState() {
    super.initState();
    if (!_hasFetched) {
      _fetchCustomers();
      _hasFetched = true;
    }
  }

  Future<void> _fetchCustomers() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('customers')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    if (!mounted) return; // ✅ Prevent calling setState after dispose

    setState(() {
      _customers = data;
    });
  }

  Future<void> _submitCustomer() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _isSaved = false;
      });

      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Not authenticated')));
        return;
      }

      try {
        await supabase.from('customers').insert({
          'user_id': user.id,
          'name': _nameController.text.trim(),
          'phone': int.tryParse(_phoneController.text.trim()) ?? 0,
          'business_name': _buinessNameController.text.trim(),
        });

        setState(() {
          _isLoading = false;
          _isSaved = true;
        });

        _formKey.currentState!.reset();
        _nameController.clear();
        _buinessNameController.clear();
        _phoneController.clear();

        await _fetchCustomers(); // Refresh customers list

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Customer saved')));
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
      }
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool validate = true,
  }) {
    bool isValid = controller.text.isNotEmpty;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: (value) {
        if (validate && (value == null || value.trim().isEmpty)) {
          return 'Required';
        }
        return null;
      },
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: isValid
            ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer, int index) {
    return Card(
      color: const Color(0xFF98AFFB),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black, width: 1),
      ),
      elevation: 0,
      shadowColor: const Color(0xFF98AFFB),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👇 Top row: Customer # & phone
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Customer ID: #${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  customer['phone']?.toString() ?? '',
                  style: const TextStyle(color: Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 👇 Name
            Text(
              customer['name'] ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            // 👇 Business name
            Text(
              customer['business_name'] ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCustomerCard(Map<String, dynamic> customer, int index) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + index * 100),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 1 * (1 - value)), // Slide from bottom
            child: child,
          ),
        );
      },
      child: _buildCustomerCard(customer, index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_customers.length / _pageSize).ceil();
    final paginatedCustomers = _customers
        .skip(_currentPage * _pageSize)
        .take(_pageSize)
        .toList();
    return SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const Text(
                    "Create new Customer",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Add your customers details to keep track of them easier.",
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 30),
                  _buildTextField(label: "Name", controller: _nameController),
                  const SizedBox(height: 14),
                  _buildTextField(
                    label: " Business Name",
                    controller: _buinessNameController,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    label: "Contact No.",
                    controller: _phoneController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitCustomer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF98AFFB),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                        side: BorderSide(
                          color: Colors.black, // 👈 Border color
                          width: 1, // 👈 Border width
                        ),
                      ),
                    ),
                    child: const Text(
                      "Create",
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "Your Customers",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (paginatedCustomers.isEmpty)
                    const Text(
                      "No customers yet.",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ...paginatedCustomers.asMap().entries.map(
                    (entry) =>
                        _buildAnimatedCustomerCard(entry.value, entry.key),
                  ),
                  if (totalPages > 1)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 8,
                        children: List.generate(totalPages, (index) {
                          return OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _currentPage = index;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: _currentPage == index
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                              backgroundColor: _currentPage == index
                                  ? Color(0xFF98AFFB)
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            child: Text(
                              "${index + 1}",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const Positioned(
              bottom: 16,
              right: 16,
              child: CircularProgressIndicator(
                color: Color(0xFF98AFFB),
                strokeWidth: 3,
              ),
            ),
        ],
      ),
    );
  }
}
