import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service_products.dart';
import '../theme/app_theme.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiServiceProducts _api = ApiServiceProducts();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _submitAdd() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final data = {
          'title': _titleController.text,
          'price': double.parse(_priceController.text),
          'category': _categoryController.text.isNotEmpty
              ? _categoryController.text
              : 'beauty',
        };

        final newProduct = await _api.addProduct(data);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Produk ditambahkan (ID ${newProduct.id})')),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SoftIconButton(
                  icon: Icons.arrow_back_rounded, onTap: () => context.pop()),
              const SizedBox(height: 18),
              const Text(
                'Produk baru',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppColors.primary),
              ),
              const SizedBox(height: 4),
              const Text('Lengkapi data produk baru.',
                  style: TextStyle(fontSize: 13, color: AppColors.secondary)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: AppStyle.panel(radius: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration:
                            AppStyle.input('Judul produk', Icons.title_rounded),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: AppStyle.input('Harga', Icons.attach_money_rounded),
                        validator: (v) => v == null || double.tryParse(v) == null
                            ? 'Masukkan angka yang valid'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _categoryController,
                        decoration: AppStyle.input(
                            'Kategori (opsional)', Icons.category_rounded),
                      ),
                      const SizedBox(height: 26),
                      _isLoading
                          ? const CircularProgressIndicator(
                              color: AppColors.primary)
                          : AppButton(
                              label: 'Simpan produk',
                              width: double.infinity,
                              onPressed: _submitAdd,
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}