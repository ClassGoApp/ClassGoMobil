import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UserLanguageBottomSheetComponent extends StatefulWidget {
  final String title;
  final List<String> items;
  final List<String> selectedItems;
  final ValueChanged<List<String>> onItemsSelected;

  const UserLanguageBottomSheetComponent({
    required this.title,
    required this.items,
    required this.onItemsSelected,
    this.selectedItems = const [],
  });

  @override
  _UserLanguageBottomSheetComponentState createState() =>
      _UserLanguageBottomSheetComponentState();
}

class _UserLanguageBottomSheetComponentState
    extends State<UserLanguageBottomSheetComponent> {
  late List<String> _filteredItems;
  late List<String> _selectedItems;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _selectedItems = List.from(widget.selectedItems);
  }

  void _filterItems(String query) {
    setState(() {
      _filteredItems = widget.items
          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: AppColors.sheetBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: TextStyle(fontSize: 18)),
          SizedBox(height: 16.0),
          TextField(
            onChanged: _filterItems,
            decoration: InputDecoration(
              hintText: 'Search ${widget.title}',
              hintStyle: TextStyle(
                color: AppColors.greyColor,
                fontSize: FontSize.scale(context, 15),
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.normal,
                fontFamily: 'SF-Pro-Text',
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.primaryWhiteColor,
              contentPadding: EdgeInsets.symmetric(
                vertical: 18.0,
                horizontal: 16.0,
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SvgPicture.asset(
                  AppImages.search,
                  width: 20,
                  height: 20,
                ),
              ),
            ),
          ),
          SizedBox(height: 16.0),
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Text(
                      'No items found',
                      style: TextStyle(color: AppColors.greyColor),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.greyColor.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                        ),
                      ],
                      borderRadius: BorderRadius.circular(8.0),
                      color: AppColors.whiteColor,
                    ),
                    child: ListView.separated(
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: ListTile(
                                title: Text(item),
                                onTap: () {
                                  setState(() {
                                    if (_selectedItems.contains(item)) {
                                      _selectedItems.remove(item);
                                    } else {
                                      _selectedItems.add(item);
                                    }
                                  });
                                  widget.onItemsSelected(_selectedItems);
                                },
                              ),
                            ),
                            Radio<String>(
                              value: item,
                              groupValue:
                                  _selectedItems.contains(item) ? item : null,
                              onChanged: (value) {
                                setState(() {
                                  if (_selectedItems.contains(item)) {
                                    _selectedItems.remove(item);
                                  } else {
                                    _selectedItems.add(item);
                                  }
                                  widget.onItemsSelected(_selectedItems);
                                });
                              },
                              activeColor: AppColors.primaryGreen,
                            ),
                          ],
                        );
                      },
                      separatorBuilder: (context, index) {
                        return Divider(
                          color: AppColors.dividerColor,
                          thickness: 1,
                          height: 1,
                          indent: 16.0,
                          endIndent: 16.0,
                        );
                      },
                    ),
                  ),
          ),
          const SizedBox(height: 25),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            child: Text(
              'Aplicar filtro',
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontSize: FontSize.scale(context, 16),
                color: AppColors.whiteColor,
                fontFamily: 'SF-Pro-Text',
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
