import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  List<dynamic> _recentOrders = [];
  bool _isLoading = false;
  late AnimationController _headerAnimationController;
  late Animation<double> _headerAnimation;

  String _selectedSort = 'Newest First';

  final List<String> _sortOptions = [
    'Newest First',
    'Oldest First',
    'Highest Price',
    'Lowest Price',
  ];

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerAnimation = CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutCubic,
    );
    _fetchRecentOrders();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    super.dispose();
  }

  void _sortOrders() {
    if (_selectedSort == 'Newest First') {
      _recentOrders.sort(
        (a, b) => DateTime.parse(
          b['created_at'],
        ).compareTo(DateTime.parse(a['created_at'])),
      );
    } else if (_selectedSort == 'Oldest First') {
      _recentOrders.sort(
        (a, b) => DateTime.parse(
          a['created_at'],
        ).compareTo(DateTime.parse(b['created_at'])),
      );
    } else if (_selectedSort == 'Highest Price') {
      _recentOrders.sort(
        (a, b) => (b['total_price'] as num).compareTo(a['total_price'] as num),
      );
    } else if (_selectedSort == 'Lowest Price') {
      _recentOrders.sort(
        (a, b) => (a['total_price'] as num).compareTo(b['total_price'] as num),
      );
    }
  }

  Future<void> _fetchRecentOrders() async {
    setState(() => _isLoading = true);

    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await supabase
          .from('orders')
          .select(
            'order_quantity, total_price, created_at, customer:customers(name), product:products(name), delivery_address, note',
          )
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(5);

      if (!mounted) return;

      setState(() {
        _recentOrders = data;
        _isLoading = false;
      });

      _headerAnimationController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error loading orders: $e')),
            ],
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order, int index) {
    final date = DateFormat(
      'dd MMM yyyy',
    ).format(DateTime.parse(order['created_at']));
    final customerName = order['customer']?['name'] ?? 'Unknown Customer';
    final productName = order['product']?['name'] ?? 'Unknown Product';
    final totalPrice = order['total_price'] ?? 0.0;
    final quantity = order['order_quantity'] ?? 0;
    final hasAddress =
        order['delivery_address'] != null &&
        order['delivery_address'].toString().trim().isNotEmpty;
    final hasNote =
        order['note'] != null && order['note'].toString().trim().isNotEmpty;

    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 400 + index * 150),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOutBack,
      builder: (context, double value, child) {
        // Ensure opacity is always between 0 and 1
        final clampedValue = value.clamp(0.0, 1.0);
        final scaleValue = (0.8 + (0.2 * clampedValue)).clamp(0.0, 1.0);

        return Transform.scale(
          scale: scaleValue,
          child: Opacity(
            opacity: clampedValue,
            child: Transform.translate(
              offset: Offset(0, 30 * (1 - clampedValue)),
              child: child,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF98AFFB),
          border: Border.all(width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Add tap functionality here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order details for $customerName'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Header Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Avatar
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          // border: Border.all(width: 1, color: Colors.black),
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: Text(
                            customerName.isNotEmpty
                                ? customerName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Color(0xFF98AFFB),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Customer Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customerName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 16,
                                  color: Colors.black,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    productName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Date Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black),
                        ),
                        child: Text(
                          date,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Details Row
                  Row(
                    children: [
                      // Quantity
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.white, Colors.white],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Icon(
                              //   Icons.inventory_2_outlined,
                              //   size: 18,
                              //   color: Colors.black.withValues(alpha: 0.8),
                              // ),
                              const SizedBox(width: 6),
                              Text(
                                'Quantity: $quantity',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Total Price
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF98FB98),
                                const Color(0xFF90EE90),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.currency_rupee,
                                size: 18,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                NumberFormat(
                                  "#,##0.0",
                                  "en_IN",
                                ).format(totalPrice),
                                style: const TextStyle(
                                  fontSize: 16,
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

                  // Address and Note (if available)
                  if (hasAddress || hasNote) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasAddress) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: Color(0xFF98AFFB),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    order['delivery_address'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF98AFFB),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (hasNote) const SizedBox(height: 8),
                          ],
                          if (hasNote) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.note_outlined,
                                  size: 16,
                                  color: Color(0xFF98AFFB),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    order['note'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF98AFFB),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 24,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No Recent Orders",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your recent orders will appear here",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchRecentOrders,
        color: const Color(0xFF98AFFB),
        backgroundColor: Colors.white,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF98AFFB)),
                ),
              )
            : _recentOrders.isEmpty
            ? _buildEmptyState()
            : CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _headerAnimation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.5),
                          end: Offset.zero,
                        ).animate(_headerAnimation),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Recent Orders",
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${_recentOrders.length} orders found",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DropdownButtonHideUnderline(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF98AFFB),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: DropdownButton<String>(
                                    value: _selectedSort,
                                    items: _sortOptions.map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(
                                          value,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedSort = value;
                                          _sortOrders();
                                        });
                                      }
                                    },
                                    isDense: true,
                                    dropdownColor: Colors.white,
                                    icon: const Icon(
                                      Icons.arrow_drop_down_rounded,
                                      color: Colors.black,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Orders List
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildOrderCard(_recentOrders[index], index),
                      childCount: _recentOrders.length,
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
      ),
    );
  }
}
