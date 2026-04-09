import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recollecto/features/ia/data/image_embedding_bridge.dart';

import '../../../core/localization/local_text.dart';
import '../../../core/widgets/app_header.dart';
import '../../items/data/item_repository.dart';
import '../../items/data/photo_storage_service.dart';
import '../../items/presentation/item_detail_page.dart';

class ImageAnalysisPage extends StatefulWidget {
  const ImageAnalysisPage({super.key});

  @override
  State<ImageAnalysisPage> createState() => _ImageAnalysisPageState();
}

class _ImageAnalysisPageState extends State<ImageAnalysisPage> {
  final PhotoStorageService _photoStorageService = PhotoStorageService();
  final ItemRepository _itemRepository = ItemRepository();
  final ImageEmbeddingBridge _bridge = ImageEmbeddingBridge();

  XFile? _selectedPhoto;
  bool _isAnalyzing = false;
  List<_ImageMatch> _matches = [];

  Future<void> _pickFromCamera() async {
    if (_isAnalyzing) return;

    final photo = await _photoStorageService.pickFromCamera();
    if (photo == null || !mounted) return;

    await _analyzePhoto(photo);
  }

  Future<void> _pickFromGallery() async {
    if (_isAnalyzing) return;

    final photos = await _photoStorageService.pickFromGallery();
    if (photos.isEmpty || !mounted) return;

    await _analyzePhoto(photos.first);
  }

  Future<void> _analyzePhoto(XFile photo) async {
    setState(() {
      _selectedPhoto = photo;
      _isAnalyzing = true;
      _matches = [];
    });

    try {
      final candidates = await _itemRepository.getImageSearchCandidates();

      final result = await _bridge.findMatches(
        queryImagePath: photo.path,
        candidates: candidates
            .where((e) => (e['photoPath'] as String?) != null)
            .map((e) => {
                  'itemId': e['itemId'],
                  'title': e['title'],
                  'categoryName': e['categoryName'],
                  'collectionName': e['collectionName'],
                  'photoPath': e['photoPath'],
                })
            .toList(),
        minScore: 0.80,
        limit: 10,
      );

      if (!mounted) return;

      setState(() {
        _matches = result.map((e) => _ImageMatch.fromMap(e)).toList();
        _isAnalyzing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isAnalyzing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              context,
              es: 'Error al analizar la imagen: $e',
              en: 'Error analyzing image: $e',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        title: tr(context, es: 'Buscador con IA', en: 'AI Image Search'),
        subtitle: tr(
          context,
          es: 'Toma una foto y busca coincidencias visuales.',
          en: 'Take a photo and search for visual matches.',
        ),
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context, es: 'Buscar por imagen', en: 'Search by image'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(
                      context,
                      es: 'Esta pantalla no guarda nada. Solo busca parecidos en tu colección.',
                      en: 'This screen saves nothing. It only searches for similar items in your collection.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isAnalyzing ? null : _pickFromCamera,
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: Text(
                            tr(context, es: 'Cámara', en: 'Camera'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isAnalyzing ? null : _pickFromGallery,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(
                            tr(context, es: 'Galería', en: 'Gallery'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedPhoto != null) ...[
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.file(
                      File(_selectedPhoto!.path),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      tr(context, es: 'Imagen consultada', en: 'Query image'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_isAnalyzing)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Buscando coincidencias...'),
                  ],
                ),
              ),
            )
          else if (_selectedPhoto != null && _matches.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  tr(
                    context,
                    es: 'No se encontraron coincidencias visuales.',
                    en: 'No visual matches were found.',
                  ),
                ),
              ),
            )
          else if (_matches.isNotEmpty) ...[
            Text(
              tr(
                context,
                es: 'Coincidencias encontradas',
                en: 'Matches found',
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._matches.map((match) => _MatchCard(match: match)),
          ],
        ],
      ),
    );
  }
}

class _ImageMatch {
  final String itemId;
  final String title;
  final String categoryName;
  final String collectionName;
  final String photoPath;
  final double score;

  _ImageMatch({
    required this.itemId,
    required this.title,
    required this.categoryName,
    required this.collectionName,
    required this.photoPath,
    required this.score,
  });

  factory _ImageMatch.fromMap(Map<String, dynamic> map) {
    return _ImageMatch(
      itemId: map['itemId'] as String,
      title: (map['title'] ?? '') as String,
      categoryName: (map['categoryName'] ?? '') as String,
      collectionName: (map['collectionName'] ?? '') as String,
      photoPath: (map['photoPath'] ?? '') as String,
      score: (map['score'] as num).toDouble(),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final _ImageMatch match;

  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final percent = (match.score * 100).toStringAsFixed(1);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ItemDetailPage(itemId: match.itemId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: Image.file(
                    File(match.photoPath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: Color(0x11000000),
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Categoría: ${match.categoryName}'),
                    const SizedBox(height: 4),
                    Text('Colección: ${match.collectionName}'),
                    const SizedBox(height: 8),
                    Text(
                      'Similitud: $percent%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
