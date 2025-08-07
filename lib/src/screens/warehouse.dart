// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WarehouseScreen extends StatefulWidget {
  const WarehouseScreen({super.key});

  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen> {
  List<Map<String, dynamic>> storages = [];
  Map<String, dynamic>? selectedStorage;
  String? selectedCell;
  List<Map<String, dynamic>> cellItems = [];

  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController productController = TextEditingController();
  final TextEditingController numberOfItemController = TextEditingController();
  final TextEditingController gradeController = TextEditingController();
  final TextEditingController subGradeController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController personNameController = TextEditingController();
  final TextEditingController suppliableToController = TextEditingController();

  // Colors
  static const Color primaryGreen = Color(0xFF98FB98);
  static const Color lightGreen = Color(0xFFE8FDE8);

  @override
  void initState() {
    super.initState();
    fetchStorages();
  }

  Future<void> fetchStorages() async {
    final String userId = supabase.auth.currentUser!.id;
    final response = await supabase
        .from('storage_info')
        .select()
        .eq('user_id', userId);

    setState(() {
      storages = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> fetchItemsForCell(String cellLabel) async {
    if (selectedStorage == null) return;
    final response = await supabase
        .from('storage_items')
        .select()
        .eq('storage_id', selectedStorage!['id'])
        .eq('cell_index', cellLabel);

    setState(() {
      cellItems = List<Map<String, dynamic>>.from(response);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Warehouse',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3748),
                    letterSpacing: -0.5,
                  ),
                ),
                _buildAddStorageButton(),
              ],
            ),
            const SizedBox(height: 32),

            // Storage Selector
            _buildStorageSelector(),

            const SizedBox(height: 24),

            // Storage Grid
            if (selectedStorage != null) ...[
              _buildStorageHeader(),
              const SizedBox(height: 16),
              Expanded(child: _buildStorageGrid()),
            ] else
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: lightGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.warehouse_outlined,
                          size: 40,
                          color: Color(0xFF4A5568),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Select a storage to view',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF718096),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddStorageButton() {
    return Container(
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showAddStorageDialog(context),
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 18, color: Color(0xFF2D3748)),
                SizedBox(width: 6),
                Text(
                  'Add Storage',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStorageSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButton<Map<String, dynamic>>(
        value: selectedStorage,
        hint: const Text(
          "Select Storage",
          style: TextStyle(color: Color(0xFF718096), fontSize: 16),
        ),
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF718096)),
        onChanged: (value) => setState(() {
          selectedStorage = value;
          selectedCell = null;
          cellItems = [];
        }),
        items: storages.map((storage) {
          return DropdownMenuItem(
            value: storage,
            child: Text(
              storage['name'],
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF2D3748),
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStorageHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${selectedStorage!['dimension_x']}×${selectedStorage!['dimension_y']} Grid',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A5568),
            ),
          ),
        ),
        const Spacer(),
        if (selectedCell != null)
          Text(
            'Selected: $selectedCell',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF718096),
            ),
          ),
      ],
    );
  }

  Widget _buildStorageGrid() {
    int x = selectedStorage!['dimension_x'];
    int y = selectedStorage!['dimension_y'];

    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: x,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: x * y,
            itemBuilder: (context, index) {
              int row = index ~/ x;
              int col = index % x;
              String cellLabel = "${String.fromCharCode(65 + row)}${col + 1}";
              bool isSelected = selectedCell == cellLabel;

              return _buildGridCell(cellLabel, isSelected);
            },
          ),
        ),
        if (selectedCell != null) ...[
          const SizedBox(height: 10),
          _buildItemDetails(),
        ],
      ],
    );
  }

  Widget _buildGridCell(String cellLabel, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() => selectedCell = cellLabel);
        fetchItemsForCell(cellLabel);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryGreen : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              cellLabel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF2D3748)
                    : const Color(0xFF718096),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D3748),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: GestureDetector(
                  onTap: () => showAddItemDialog(cellLabel),
                  child: const Text(
                    'Add Item',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Items in $selectedCell',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 12),
          if (cellItems.isEmpty)
            const Text(
              'No items stored in this cell',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF718096),
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...cellItems.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['product'] ?? 'Unknown Product',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Grade: ${item['grade']} • ${item['number_of_item']} items',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF718096),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void showAddItemDialog(String cellLabel) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Add Item',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: lightGreen,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Cell $cellLabel',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A5568),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildTextField(
                        productController,
                        'Product',
                        Icons.inventory_2_outlined,
                      ),
                      _buildTextField(
                        numberOfItemController,
                        'Quantity',
                        Icons.numbers,
                        TextInputType.number,
                      ),
                      _buildTextField(
                        gradeController,
                        'Grade',
                        Icons.grade_outlined,
                      ),
                      _buildTextField(
                        subGradeController,
                        'Sub Grade',
                        Icons.category_outlined,
                      ),
                      _buildTextField(
                        weightController,
                        'Weight (kg)',
                        Icons.scale_outlined,
                        TextInputType.number,
                      ),
                      _buildTextField(
                        priceController,
                        'Price',
                        Icons.attach_money,
                        TextInputType.number,
                      ),
                      _buildTextField(
                        personNameController,
                        'Person Name',
                        Icons.person_outlined,
                      ),
                      _buildTextField(
                        suppliableToController,
                        'Suppliable To',
                        Icons.local_shipping_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          _clearControllers();
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Color(0xFF718096),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _saveItem(cellLabel),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: const Color(0xFF2D3748),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Save Item',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, [
    TextInputType? inputType,
  ]) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFF718096)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primaryGreen, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          labelStyle: const TextStyle(color: Color(0xFF718096), fontSize: 14),
        ),
      ),
    );
  }

  Future<void> _saveItem(String cellLabel) async {
    final product = productController.text.trim();
    final numberOfItem = int.tryParse(numberOfItemController.text);
    final grade = gradeController.text.trim();
    final subgrade = subGradeController.text.trim();
    final weight = double.tryParse(weightController.text);
    final price = double.tryParse(priceController.text);
    final personName = personNameController.text.trim();
    final suppliableTo = suppliableToController.text.trim();

    if (product.isEmpty || numberOfItem == null || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all required fields.'),
          backgroundColor: Colors.red.shade400,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await supabase.from('storage_items').insert({
        'product': product,
        'number_of_item': numberOfItem,
        'grade': grade,
        'subgrade': subgrade,
        'weight': weight,
        'price': price,
        'person_name': personName,
        'suppliable_to': suppliableTo,
        'cell_index': cellLabel,
        'storage_id': selectedStorage!['id'],
      });

      _clearControllers();
      Navigator.pop(context);
      fetchItemsForCell(cellLabel);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Item added successfully!'),
          backgroundColor: primaryGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade400,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _clearControllers() {
    productController.clear();
    numberOfItemController.clear();
    gradeController.clear();
    subGradeController.clear();
    weightController.clear();
    priceController.clear();
    personNameController.clear();
    suppliableToController.clear();
  }

  void showAddStorageDialog(BuildContext context) {
    final nameController = TextEditingController();
    final dimXController = TextEditingController();
    final dimYController = TextEditingController();
    final capController = TextEditingController();
    final supervisorController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Create Storage",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                nameController,
                "Storage Name",
                Icons.warehouse_outlined,
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      dimXController,
                      "Width",
                      Icons.width_normal,
                      TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      dimYController,
                      "Height",
                      Icons.height,
                      TextInputType.number,
                    ),
                  ),
                ],
              ),
              _buildTextField(capController, "Capacity", Icons.inventory),
              _buildTextField(supervisorController, "Supervisor", Icons.person),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF718096),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text;
                        final dimX = int.tryParse(dimXController.text) ?? 0;
                        final dimY = int.tryParse(dimYController.text) ?? 0;
                        final capacity = capController.text;
                        final supervisor = supervisorController.text;
                        final userId = supabase.auth.currentUser?.id;

                        if (name.isEmpty || dimX == 0 || dimY == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Please fill all required fields.',
                              ),
                              backgroundColor: Colors.red.shade400,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        try {
                          await supabase.from('storage_info').insert({
                            'name': name,
                            'dimension_x': dimX,
                            'dimension_y': dimY,
                            'capacity': capacity,
                            'supervisor': supervisor,
                            'user_id': userId,
                          });

                          Navigator.pop(context);
                          fetchStorages();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Storage created successfully!',
                              ),
                              backgroundColor: primaryGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red.shade400,
                              // shape: RoundedRectangleBarter(
                              //   borderRadius: BorderRadius.circular(8),
                              // ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: const Color(0xFF2D3748),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Create Storage',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    productController.dispose();
    numberOfItemController.dispose();
    gradeController.dispose();
    subGradeController.dispose();
    weightController.dispose();
    priceController.dispose();
    personNameController.dispose();
    suppliableToController.dispose();
    super.dispose();
  }
}
