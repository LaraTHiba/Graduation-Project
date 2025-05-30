import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../languages/language.dart';

class CVSearchDialog extends StatefulWidget {
  const CVSearchDialog({Key? key}) : super(key: key);

  @override
  State<CVSearchDialog> createState() => _CVSearchDialogState();
}

class _CVSearchDialogState extends State<CVSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _hasSearched = false;
  List<Map<String, dynamic>> _results = [];
  String? _error;

  void _onSearch() async {
    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _error = null;
    });
    try {
      final response =
          await ApiService().searchCVs(_searchController.text.trim());
      final results = response;
      setState(() {
        _results = List<Map<String, dynamic>>.from(results);
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _results = [];
      });
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = context.read<Language>();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.search, color: Color(0xFF006C5F)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: language.get('Cv search hint'),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _onSearch(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: Text(language.get('Cv search')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006C5F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _onSearch,
            ),
            const SizedBox(height: 24),
            if (_isSearching)
              const CircularProgressIndicator()
            else if (_error != null)
              SizedBox(
                height: 200,
                child: SingleChildScrollView(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              )
            else if (_results.isNotEmpty)
              SizedBox(
                height: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final profile = _results[index];
                    return ListTile(
                      leading: const Icon(Icons.description),
                      title: Text(profile['user']?['username'] ?? ''),
                      subtitle: Text(profile['cv_original_filename'] ?? ''),
                      trailing: profile['cv_file_url'] != null
                          ? IconButton(
                              icon: const Icon(Icons.download),
                              tooltip: language.get('Download cv'),
                              onPressed: () async {
                                final url = profile['cv_file_url'];
                                if (url != null && await canLaunch(url)) {
                                  await launch(url,
                                      webOnlyWindowName: '_blank');
                                }
                              },
                            )
                          : null,
                    );
                  },
                ),
              )
            else if (!_isSearching && _results.isEmpty && _hasSearched)
              Text(language.get('Cv no results'))
            else if (!_isSearching && _results.isEmpty && !_hasSearched)
              Text(language.get('Cv no results yet')),
          ],
        ),
      ),
    );
  }
}
