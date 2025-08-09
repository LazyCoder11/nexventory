// ignore_for_file: use_build_context_synchronously, unused_field, unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();

  bool _isLoading = false;
  bool _isSaved = false;
  List<dynamic> _products = [];

  final supabase = Supabase.instance.client;

  int _currentPage = 0;
  final int _pageSize = 5;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
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

    setState(() {
      _products = data;
    });
  }

  Future<void> _fetchOrdersForProduct(dynamic productId) async {
    final data = await supabase
        .from('orders')
        .select(
          'order_quantity, total_price, created_at, customer:customers(name)',
        )
        .eq('product_id', productId)
        .order('created_at', ascending: false);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(width: 1),
        ),
        shadowColor: Colors.black,
        elevation: 2,
        // backgroundColor: Color(0xFF98AFFB),
        title: const Text('Recent Orders'),
        content: SizedBox(
          width: double.maxFinite,
          child: data.isEmpty
              ? const Text("No orders found for this product.")
              : Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF98AFFB),
                    border: Border.all(width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    separatorBuilder: (_, __) => Divider(),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final order = data[index];
                      final date = DateFormat(
                        'dd-MM-yyyy',
                      ).format(DateTime.parse(order['created_at']));
                      return ListTile(
                        title: Text(
                          'Qty: ${order['order_quantity']} - ₹${order['total_price']}',
                        ),
                        subtitle: Text(
                          'Customer: ${order['customer']['name']}\n$date',
                        ),
                      );
                    },
                  ),
                ),
        ),
        // actions: [
        //   TextButton(
        //     onPressed: () => Navigator.pop(context),
        //     child: const Text("Close"),
        //   ),
        // ],
      ),
    );
  }

  Future<void> _submitProduct() async {
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
        await supabase.from('products').insert({
          'user_id': user.id,
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
          'quantity': int.tryParse(_quantityController.text.trim()) ?? 0,
        });

        setState(() {
          _isLoading = false;
          _isSaved = true;
        });

        _formKey.currentState!.reset();
        _nameController.clear();
        _descriptionController.clear();
        _priceController.clear();
        _quantityController.clear();

        await _fetchProducts();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Product saved')));
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
    bool validate = true,
  }) {
    bool isValid = controller.text.isNotEmpty;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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

  Widget _buildProductCard(Map<String, dynamic> product, int index) {
    String formatDate(String? isoDate) {
      if (isoDate == null) return '';
      try {
        final parsedDate = DateTime.parse(isoDate);
        return DateFormat('dd-MM-yyyy').format(parsedDate);
      } catch (_) {
        return '';
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFF98AFFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _fetchOrdersForProduct(product['id']),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row with Product Icon and Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(width: 1),
                        gradient: LinearGradient(
                          colors: [Colors.white, Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.inventory_2,
                          color: Colors.black,
                          size: 28,
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Product Name and Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  product['name'] ?? 'Unknown Product',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              // Order Status Badge
                              // Container(
                              //   padding: const EdgeInsets.symmetric(
                              //     horizontal: 12,
                              //     vertical: 6,
                              //   ),
                              //   decoration: BoxDecoration(
                              //     color: hasOrders
                              //         ? const Color(
                              //             0xFF98AFFB,
                              //           ).withValues(alpha: 0.2)
                              //         : Colors.orange.withValues(alpha: 0.2),
                              //     borderRadius: BorderRadius.circular(16),
                              //     border: Border.all(
                              //       color: hasOrders
                              //           ? const Color(0xFF98AFFB)
                              //           : Colors.orange,
                              //       width: 1,
                              //     ),
                              //   ),
                              //   child: Row(
                              //     mainAxisSize: MainAxisSize.min,
                              //     children: [
                              //       Icon(
                              //         hasOrders
                              //             ? Icons.check_circle_outline
                              //             : Icons.pending_outlined,
                              //         size: 14,
                              //         color: hasOrders
                              //             ? const Color(0xFF98AFFB)
                              //             : Colors.orange,
                              //       ),
                              //       const SizedBox(width: 4),
                              //       Text(
                              //         hasOrders ? 'Has Orders' : 'No Orders',
                              //         style: TextStyle(
                              //           fontSize: 11,
                              //           fontWeight: FontWeight.w600,
                              //           color: hasOrders
                              //               ? const Color(0xFF98AFFB)
                              //               : Colors.orange,
                              //         ),
                              //       ),
                              //     ],
                              //   ),
                              // ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Date
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 14,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formatDate(product['created_at']),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Description
                if (product['description'] != null &&
                    product['description'].toString().trim().isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFF98AFFB)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 16,
                          color: Color(0xFF98AFFB),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            product['description'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF98AFFB),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Price and Quantity Row
                Row(
                  children: [
                    // Price Container
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(width: 1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // const Icon(
                                //   Icons.currency_rupee,
                                //   color: Colors.black,
                                //   size: 16,
                                // ),
                                // const SizedBox(width: 4),
                                const Text(
                                  'Price',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${NumberFormat("#,##0.0", "en_IN").format(product['price'] ?? 0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Quantity Container
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Icon(
                                //   Icons.inventory_outlined,
                                //   color: Colors.black,
                                //   size: 18,
                                // ),
                                // const SizedBox(width: 4),
                                Text(
                                  'Stock',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${product['quantity'] ?? 0}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action Button
                // Container(
                //   width: double.infinity,
                //   height: 48,
                //   decoration: BoxDecoration(
                //     gradient: LinearGradient(
                //       colors: hasOrders
                //           ? [
                //               const Color(0xFF98AFFB).withValues(alpha: 0.8),
                //               const Color(0xFF90EE90).withValues(alpha: 0.8),
                //             ]
                //           : [Colors.grey.shade300, Colors.grey.shade400],
                //       begin: Alignment.topLeft,
                //       end: Alignment.bottomRight,
                //     ),
                //     borderRadius: BorderRadius.circular(12),
                //   ),
                //   child: Material(
                //     color: Colors.transparent,
                //     child: InkWell(
                //       onTap: () => _fetchOrdersForProduct(product['id']),
                //       borderRadius: BorderRadius.circular(12),
                //       child: Center(
                //         child: Row(
                //           mainAxisAlignment: MainAxisAlignment.center,
                //           children: [
                //             Icon(
                //               hasOrders
                //                   ? Icons.visibility_outlined
                //                   : Icons.add_shopping_cart_outlined,
                //               color: hasOrders
                //                   ? Colors.white
                //                   : Colors.grey.shade700,
                //               size: 20,
                //             ),
                //             const SizedBox(width: 8),
                //             Text(
                //               hasOrders ? 'View Orders' : 'No Orders Yet',
                //               style: TextStyle(
                //                 fontSize: 16,
                //                 fontWeight: FontWeight.w600,
                //                 color: hasOrders
                //                     ? Colors.white
                //                     : Colors.grey.shade700,
                //               ),
                //             ),
                //           ],
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedProductCard(Map<String, dynamic> customer, int index) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + index * 100),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 1 * (1 - value)),
            child: child,
          ),
        );
      },
      child: _buildProductCard(customer, index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_products.length / _pageSize).ceil();
    final paginatedProducts = _products
        .skip(_currentPage * _pageSize)
        .take(_pageSize)
        .toList();

    return SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 24.0, top: 24.0, right: 24.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const Text(
                    "Create new product",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Add your product details to keep track of them easier.",
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 30),
                  _buildTextField(label: "Name", controller: _nameController),
                  const SizedBox(height: 14),
                  _buildTextField(
                    label: "Description",
                    controller: _descriptionController,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    label: "Price",
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    label: "Quantity",
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF98AFFB),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                        side: BorderSide(color: Colors.black, width: 1),
                      ),
                    ),
                    child: const Text(
                      "Create",
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "Your Products",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (paginatedProducts.isEmpty)
                    const Text(
                      "No products yet.",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ...paginatedProducts.asMap().entries.map(
                    (entry) =>
                        _buildAnimatedProductCard(entry.value, entry.key),
                  ),
                  const SizedBox(height: 24),
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
