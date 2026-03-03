import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class SearchSubjectModal extends StatefulWidget {
  final List<dynamic> initialSubjects;
  final Future<List<dynamic>> Function(String keyword) onSearch;
  final void Function(Map<String, dynamic> subject) onSubjectSelected;

  const SearchSubjectModal({
    Key? key,
    required this.initialSubjects,
    required this.onSearch,
    required this.onSubjectSelected,
  }) : super(key: key);

  @override
  State<SearchSubjectModal> createState() => _SearchSubjectModalState();
}

class _SearchSubjectModalState extends State<SearchSubjectModal> {
  late List<dynamic> _subjects;
  bool _isLoading = false;
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _subjects = widget.initialSubjects;
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isLoading = true);
      final results = await widget.onSearch(value);
      setState(() {
        _subjects = results;
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          minHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        decoration: BoxDecoration(
          color: AppColors.darkBlue,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Busca tu materia...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                  prefixIcon: Icon(Icons.search, color: Colors.white),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Divider(color: Colors.white.withOpacity(0.1), height: 1),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: AppColors.lightBlueColor))
                  : ListView.separated(
                      itemCount: _subjects.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.white.withOpacity(0.1),
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, index) {
                        final subject = _subjects[index];
                        return ListTile(
                          title: Text(
                            subject['name'] ?? 'Materia desconocida',
                            style: TextStyle(color: Colors.white),
                          ),
                          onTap: () {
                            widget.onSubjectSelected(subject);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}