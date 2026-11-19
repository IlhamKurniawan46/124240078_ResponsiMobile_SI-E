import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/snackbar_helper.dart';

class DetailScreen extends StatefulWidget {
  final int id;
  final ApiService? apiService;
  final StorageService? storageService;

  const DetailScreen({
    super.key,
    this.id = 0,
    this.apiService,
    this.storageService,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late final ApiService _apiService;
  late final StorageService _storageService;
  Recipe? _recipe;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    _storageService = widget.storageService ?? StorageService();
    _fetchDetail();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final fav = await _storageService.isFavorite(widget.id);
    if (mounted) {
      setState(() {
        _isFavorite = fav;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      await _storageService.removeFavorite(widget.id);
      if (!mounted) return;
      setState(() {
        _isFavorite = false;
      });
      SnackbarHelper.showSuccess(
        context,
        AppConstants.removedFromFavoriteMessage,
      );
    } else {
      if (_recipe == null) return;
      await _storageService.addFavorite(_recipe!);
      if (!mounted) return;
      setState(() {
        _isFavorite = true;
      });
      SnackbarHelper.showSuccess(
        context,
        AppConstants.addedToFavoriteMessage,
      );
    }
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.getRecipeDetail(widget.id);
      if (mounted) {
        setState(() {
          _recipe = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e is ApiException ? e.message : e.toString();
        });
      }
    }
  }

  Widget _buildBannerImage(String imageUrl) {
    const double bannerHeight = 250.0;

    if (imageUrl.trim().isEmpty) {
      return Container(
        height: bannerHeight,
        width: double.infinity,
        color: Colors.grey.shade300,
        child: const Center(
          child: Icon(
            Icons.broken_image,
            size: 64,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Image.network(
      imageUrl,
      height: bannerHeight,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: bannerHeight,
          width: double.infinity,
          color: Colors.grey.shade200,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: bannerHeight,
          width: double.infinity,
          color: Colors.grey.shade300,
          child: const Center(
            child: Icon(
              Icons.broken_image,
              size: 64,
              color: Colors.grey,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          key: Key('detail_loading_indicator'),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                key: const Key('detail_retry_button'),
                onPressed: _fetchDetail,
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_recipe == null) {
      return const Center(
        child: Text('Data tidak tersedia.'),
      );
    }

    final recipe = _recipe!;
    final mealTypesText = recipe.mealType.isNotEmpty
        ? ' • ${recipe.mealType.join(', ')}'
        : '';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBannerImage(recipe.image),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.name.isNotEmpty ? recipe.name : 'Tidak ada judul',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${recipe.cuisine}$mealTypesText',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      Icons.star,
                      '${recipe.rating} (${recipe.reviewCount})',
                    ),
                    _buildInfoChip(Icons.speed, recipe.difficulty),
                    _buildInfoChip(
                      Icons.timer_outlined,
                      'Persiapan ${recipe.prepTimeMinutes} mnt',
                    ),
                    _buildInfoChip(
                      Icons.local_fire_department_outlined,
                      'Masak ${recipe.cookTimeMinutes} mnt',
                    ),
                    _buildInfoChip(
                      Icons.people_outline,
                      '${recipe.servings} porsi',
                    ),
                    _buildInfoChip(
                      Icons.bolt,
                      '${recipe.caloriesPerServing} kal/porsi',
                    ),
                  ],
                ),
                const Divider(height: 32),
                const Text(
                  'Bahan-bahan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...recipe.ingredients.map(
                  (ingredient) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      '• $ingredient',
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Langkah Memasak',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(recipe.instructions.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            recipe.instructions[index],
                            style: const TextStyle(fontSize: 15, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Resep'),
        actions: [
          IconButton(
            key: const Key('detail_favorite_button'),
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            tooltip: _isFavorite ? 'Hapus dari favorite' : 'Tambah ke favorite',
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}
