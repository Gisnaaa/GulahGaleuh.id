import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.product.title);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _stockController = TextEditingController(text: widget.product.stock.toString());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _submitEdit() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<ProductProvider>(context, listen: false);

      Product updatedProduct = widget.product.copyWith(
        title: _titleController.text,
        price: double.parse(_priceController.text),
        stock: int.parse(_stockController.text),
      );

      bool success = await provider.updateProduct(widget.product.id, updatedProduct);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perubahan disimpan')),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perubahan gagal disimpan, coba lagi')),
          );
        }
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
              Text(
                'Edit produk #${widget.product.id}',
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppColors.primary),
              ),
              const SizedBox(height: 4),
              const Text('Ubah data produk, lalu simpan.',
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
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: AppStyle.input('Stok', Icons.inventory_2_rounded),
                        validator: (v) => v == null || int.tryParse(v) == null
                            ? 'Masukkan angka yang valid'
                            : null,
                      ),
                      const SizedBox(height: 26),
                      Consumer<ProductProvider>(
                        builder: (context, provider, child) {
                          return provider.loading
                              ? const CircularProgressIndicator(
                                  color: AppColors.primary)
                              : AppButton(
                                  label: 'Simpan perubahan',
                                  width: double.infinity,
                                  onPressed: _submitEdit,
                                );
                        },
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