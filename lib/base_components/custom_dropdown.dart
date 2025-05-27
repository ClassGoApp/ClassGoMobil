import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomDropdown extends StatefulWidget {
  final String hint;
  final String? selectedValue;
  final List<String> items;
  final Function(String) onSelected;

  CustomDropdown({
    required this.hint,
    required this.selectedValue,
    required this.items,
    required this.onSelected,
  });

  @override
  _CustomDropdownState createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  String? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.selectedValue;
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: AppColors.primaryGreen,
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.45,
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          decoration: BoxDecoration(
            color: AppColors.sheetBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 10, top: 2),
                  decoration: BoxDecoration(
                    color: AppColors.topBottomSheetDismissColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 5.0, horizontal: 16.0),
                child: Text(
                  'Selecciona una opción',
                  style: TextStyle(
                    fontSize: FontSize.scale(context, 18),
                    color: AppColors.blackColor,
                    fontFamily: 'SF-Pro-Text',
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.normal,
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.greyColor.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                        ),
                      ],
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16.0),
                      ),
                    ),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      physics: AlwaysScrollableScrollPhysics(),
                      itemCount: widget.items.length,
                      separatorBuilder: (BuildContext context, int index) {
                        return Divider(
                          color: AppColors.dividerColor,
                          height: 0,
                          thickness: 0.5,
                          indent: 24,
                          endIndent: 24,
                        );
                      },
                      itemBuilder: (BuildContext context, int index) {
                        final value = widget.items[index];
                        return ListTile(
                          onTap: () {
                            setState(() {
                              _selectedValue = value;
                            });
                            Navigator.pop(context);
                            widget.onSelected(value);
                          },
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                value,
                                style: TextStyle(
                                  color: AppColors.greyColor,
                                  fontSize: FontSize.scale(context, 16),
                                  fontWeight: FontWeight.w400,
                                  fontFamily: "SF-Pro-Text",
                                ),
                              ),
                              Transform.scale(
                                scale: 1.35,
                                child: Checkbox(
                                    value: _selectedValue == value,
                                    onChanged: (bool? newValue) {
                                      setState(() {
                                        _selectedValue = value;
                                      });
                                      Navigator.pop(context);
                                      widget.onSelected(value);
                                    },
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(5.0),
                                      ),
                                    ),
                                    side: BorderSide(
                                      color: AppColors.dividerColor,
                                      width: 1,
                                    ),
                                    activeColor: AppColors.primaryGreen),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showBottomSheet(context),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SvgPicture.asset(
              AppImages.sorting,
              width: 16,
              height: 16,
              alignment: Alignment.center,
              color: AppColors.whiteColor,
            ),
            SizedBox(width: 5),
            Text(
              _selectedValue != null
                  ? 'Ordenar por: $_selectedValue'
                  : 'Ordenar por: ${widget.hint}',
              style: TextStyle(
                color: AppColors.whiteColor,
                fontSize: FontSize.scale(context, 14),
                fontWeight: FontWeight.w500,
                fontFamily: "SF-Pro-Text",
              ),
            ),
            Transform.translate(
              offset: Offset(2, 2),
              child: SvgPicture.asset(
                AppImages.arrowDown,
                width: 20,
                height: 20,
                color: AppColors.whiteColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
