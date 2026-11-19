import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/recipe_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/snackbar_helper.dart';

class DetailScreen extends StatefulWidget {
  final ContentType type;
  final int id;
  final ApiService? apiService;
  final StorageService? storageService;
  final Future<bool> Function(Uri, {LaunchMode mode})? urlLauncher;

  const DetailScreen({
    super.key,
    this.type = ContentType.recipes,
    this.id = 0,
    this.apiService,
    this.storageService,
    this.urlLauncher,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late final ApiService _apiService;
  late final StorageService _storageService;
  RecipeModel? _recipe;
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
    final fav = await _storageService.isFavorite(widget.type, widget.id);
    if (mounted) {
      setState(() {
        _isFavorite = fav;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      await _storageService.removeFavorite(widget.type, widget.id);
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
      final data = await _apiService.fetchDetail(widget.type, widget.id);
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

  Future<void> _openWeb(String? urlString) async {
    if (urlString == null || urlString.trim().isEmpty) {
      if (mounted) {
        SnackbarHelper.showError(context, AppConstants.openWebErrorMessage);
      }
      return;
    }

    final uri = Uri.tryParse(urlString.trim());
    if (uri == null) {
      if (mounted) {
        SnackbarHelper.showError(context, AppConstants.openWebErrorMessage);
      }
      return;
    }

    try {
      final launched = widget.urlLauncher != null
          ? await widget.urlLauncher!(uri, mode: LaunchMode.externalApplication)
          : await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!launched && mounted) {
        SnackbarHelper.showError(context, AppConstants.openWebErrorMessage);
      }
    } catch (_) {
      if (mounted) {
        SnackbarHelper.showError(context, AppConstants.openWebErrorMessage);
      }
    }
  }

  Widget _buildBannerImage(String? imageUrl) {
    const double bannerHeight = 250.0;

    if (imageUrl == null || imageUrl.trim().isEmpty) {
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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBannerImage(_recipe!.imageUrl),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _recipe!.name.isNotEmpty
                      ? _recipe!.name
                      : 'Tidak ada judul',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _recipe!.tags.isNotEmpty
                            ? _recipe!.tags
                            : 'Unknown',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _recipe!.publishedAt.isNotEmpty
                            ? _recipe!.publishedAt
                            : '-',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // Summary
                Text(
                  _recipe!.summary.isNotEmpty
                      ? _recipe!.summary
                      : 'Tidak ada ringkasan tersedia.',
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 80),
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
        title: Text('Detail ${widget.type.displayName}'),
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
      floatingActionButton: _recipe == null
          ? null
          : FloatingActionButton(
              key: const Key('detail_open_web_fab'),
              tooltip: 'Buka Web',
              onPressed: () => _openWeb(_recipe!.url),
              child: const Icon(Icons.open_in_new),
            ),
    );
  }
}