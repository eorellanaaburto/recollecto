import 'package:flutter/material.dart';

import '../../../core/localization/local_text.dart';
import '../../items/data/item_repository.dart';
import '../../items/domain/models/duplicate_group_model.dart';

class DuplicatesPage extends StatefulWidget {
  const DuplicatesPage({super.key});

  @override
  State<DuplicatesPage> createState() => _DuplicatesPageState();
}

class _DuplicatesPageState extends State<DuplicatesPage> {
  final ItemRepository _itemRepository = ItemRepository();

  final List<DuplicateGroupModel> _nameGroups = [];
  final List<DuplicateGroupModel> _imageGroups = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDuplicates();
  }

  Future<void> _loadDuplicates() async {
    setState(() {
      _isLoading = true;
    });

    final nameGroups = await _itemRepository.getDuplicateGroupsByTitle();
    final imageGroups = await _itemRepository.getDuplicateGroupsByImageHash();

    if (!mounted) return;

    setState(() {
      _nameGroups
        ..clear()
        ..addAll(nameGroups);
      _imageGroups
        ..clear()
        ..addAll(imageGroups);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasAnyDuplicates = _nameGroups.isNotEmpty || _imageGroups.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, es: 'Duplicados', en: 'Duplicates')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDuplicates,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (!hasAnyDuplicates)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          tr(context,
                              es: 'No se detectaron duplicados todavía.',
                              en: 'No duplicates have been detected yet.'),
                        ),
                      ),
                    ),
                  if (_nameGroups.isNotEmpty) ...[
                    Text(
                      tr(context,
                          es: 'Coincidencias por nombre',
                          en: 'Matches by name'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._nameGroups.map(
                      (group) => Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.text_fields),
                          ),
                          title: Text(group.displayValue),
                          subtitle: Text(
                            tr(context,
                                es: '${group.duplicateCount} ítems comparten este nombre',
                                en: '${group.duplicateCount} items share this name'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (_imageGroups.isNotEmpty) ...[
                    Text(
                      tr(context,
                          es: 'Coincidencias exactas por foto',
                          en: 'Exact matches by photo'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._imageGroups.map(
                      (group) => Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.photo_library_outlined),
                          ),
                          title: Text(group.displayValue),
                          subtitle: Text(
                            tr(context,
                                es: '${group.duplicateCount} ítems comparten esta imagen',
                                en: '${group.duplicateCount} items share this image'),
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
}
