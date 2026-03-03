import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BottomSheetComponent extends StatefulWidget {
  final String title;
  final List<String> items;
  final ValueChanged<String> onItemSelected;
  final String? selectedItem;

  const BottomSheetComponent({
    required this.title,
    required this.items,
    required this.onItemSelected,
    this.selectedItem,
  });

  @override
  _BottomSheetComponentState createState() => _BottomSheetComponentState();
}

class _BottomSheetComponentState extends State<BottomSheetComponent> {
  String _searchQuery = '';
  late List<String> _filteredItems;
  late String? _selectedItem;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _selectedItem = widget.selectedItem;
  }

  void _filterItems(String query) {
    setState(() {
      _searchQuery = query;
      _filteredItems = widget.items
          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: AppColors.sheetBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 10,top:1),
              decoration: BoxDecoration(
                color: AppColors.topBottomSheetDismissColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Text(
            "Search Option below",
            style: TextStyle(
              fontSize: FontSize.scale(context, 18),
              color:  AppColors.blackColor,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.normal,
              fontFamily: 'SF-Pro-Text',
            ),
          ),
          SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: _filterItems,
                  decoration: InputDecoration(
                    hintText: 'Search ${widget.title}',
                    hintStyle: TextStyle(
                      color:  AppColors.greyColor,
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
                    fillColor: AppColors.whiteColor,
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
              ),
            ],
          ),
          SizedBox(height: 16.0),
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
              child: Text(
                'No items found',
                style: TextStyle(color: Colors.grey),
              ),
            )
                : Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
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
                          contentPadding:
                          EdgeInsets.symmetric(horizontal: 16.0),
                          title: Text(
                            item,
                            style: TextStyle(
                              color: AppColors.greyColor,
                              fontSize: FontSize.scale(context, 16),
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.normal,
                              fontFamily: 'SF-Pro-Text',
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedItem = item;
                            });
                            widget.onItemSelected(item);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      Radio<String>(
                        value: item,
                        groupValue: _selectedItem,
                        onChanged: (value) {
                          setState(() {
                            _selectedItem = value;
                          });
                          widget.onItemSelected(value!);
                          Navigator.pop(context);
                        },
                        activeColor:AppColors.primaryGreen,
                        fillColor:
                        WidgetStateProperty.resolveWith<Color?>(
                              (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppColors.primaryGreen;
                            }
                            return AppColors.greyColor;
                          },
                        ),
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
          SizedBox(height: 20)
        ],
      ),
    );
  }
}
