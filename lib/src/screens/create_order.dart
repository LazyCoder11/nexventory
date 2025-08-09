// ignore_for_file: use_build_context_synchronously

import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _noteController = TextEditingController();

  final supabase = Supabase.instance.client;

  List<dynamic> _customers = [];
  List<dynamic> _products = [];
  dynamic _selectedCustomer;
  dynamic _selectedProduct;
  int _stock = 0;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
    _fetchProducts();

    _quantityController.addListener(() {
      if (!mounted) return;
      if (_selectedProduct != null) {
        final qty = int.tryParse(_quantityController.text.trim()) ?? 0;
        final price = _selectedProduct['price'] ?? 0;
        final total = qty * price;
        _priceController.text = total.toStringAsFixed(2);
      }
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomers() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    final data = await supabase
        .from('customers')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    if (!mounted) return;
    setState(() => _customers = data);
  }

  Future<void> _fetchProducts() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    final data = await supabase
        .from('products')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    if (!mounted) return;
    setState(() => _products = data);
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate() ||
        _selectedCustomer == null ||
        _selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Please complete all required fields."),
        ),
      );
      return;
    }

    final orderQty = int.tryParse(_quantityController.text.trim()) ?? 0;
    if (orderQty > _stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "⚠️ Only $_stock items are available in stock. Please reduce your order quantity.",
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ User not logged in.")));
      return;
    }

    final totalPrice = double.tryParse(_priceController.text.trim()) ?? 0;

    try {
      await supabase.from('orders').insert({
        'user_id': user.id,
        'customer_id': _selectedCustomer['id'],
        'product_id': _selectedProduct['id'],
        'order_quantity': orderQty,
        'total_price': totalPrice,
        'delivery_address': _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        'note': _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      });

      final newStock = _stock - orderQty;
      await supabase
          .from('products')
          .update({'quantity': newStock})
          .eq('id', _selectedProduct['id']);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Order placed successfully!')),
      );

      setState(() {
        _isLoading = false;
        _quantityController.clear();
        _addressController.clear();
        _priceController.clear();
        _noteController.clear();
        _selectedCustomer = null;
        _selectedProduct = null;
        _stock = 0;
      });

      _fetchProducts();
    } catch (e) {
      log('Error creating order: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);

      // Friendly error fallback
      String errorMessage =
          'Something went wrong while placing your order. Please try again.';

      // You can add more specific error checks here if needed
      if (e.toString().contains('network')) {
        errorMessage =
            '📶 Network error. Please check your internet connection.';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ $errorMessage')));
    }
  }

  Widget _buildDropdown<T>({
    required String label,
    required List<T> items,
    required T? selectedItem,
    required String Function(T) labelBuilder,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField2<T>(
      isExpanded: true,
      value: selectedItem,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      dropdownStyleData: DropdownStyleData(
        width: 180,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Color(0xFF98AFFB),
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      items: items.map((item) {
        final isSelected = item == selectedItem;
        return DropdownMenuItem<T>(
          value: item,
          enabled: !isSelected,
          child: Text(
            labelBuilder(item),
            style: TextStyle(color: Colors.black),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
          if (label == "Product") {
            final product = value as Map<String, dynamic>;
            if (!mounted) return;
            setState(() {
              _stock = product['quantity'] ?? 0;
              final qty = int.tryParse(_quantityController.text.trim()) ?? 0;
              final price = product['price'] ?? 0;
              final total = price * qty;
              _priceController.text = total.toStringAsFixed(2);
            });
          }
        }
      },
      validator: (value) => value == null ? 'Required' : null,
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Required';
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const Text(
                    "Create New Order",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Fill out the order details.",
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 30),
                  _buildDropdown(
                    label: "Customer",
                    items: _customers,
                    selectedItem: _selectedCustomer,
                    labelBuilder: (item) =>
                        "${item['name']} (${item['business_name']})",
                    onChanged: (val) => setState(() => _selectedCustomer = val),
                  ),
                  const SizedBox(height: 14),
                  _buildDropdown(
                    label: "Product",
                    items: _products,
                    selectedItem: _selectedProduct,
                    labelBuilder: (item) => item['name'],
                    onChanged: (val) => setState(() => _selectedProduct = val),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedProduct != null)
                    Text(
                      "Stock available: $_stock",
                      style: const TextStyle(color: Colors.green),
                    ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    label: "Order Quantity",
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    label: "Total Price",
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: 'Special Note (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Delivery Address (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF98AFFB),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                        side: const BorderSide(color: Colors.black, width: 1),
                      ),
                    ),
                    child: const Text(
                      "Create Order",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const Positioned(
              bottom: 16,
              right: 16,
              child: CircularProgressIndicator(color: Color(0xFF98AFFB)),
            ),
        ],
      ),
    );
  }
}
