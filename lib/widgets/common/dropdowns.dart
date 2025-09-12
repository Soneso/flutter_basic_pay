// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:math';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

class StringItemsDropdown extends StatefulWidget {
  final String title;
  final List<String> items;
  final ValueChanged<String> onItemSelected;
  final String? initialSelectedItem;

  const StringItemsDropdown({
    required this.title,
    required this.items,
    required this.onItemSelected,
    this.initialSelectedItem,
    super.key,
  });

  @override
  State<StringItemsDropdown> createState() => _StringItemsDropdownState();
}

class _StringItemsDropdownState extends State<StringItemsDropdown> {
  String? _selectedValue;
  
  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialSelectedItem;
  }
  
  String _truncateMiddle(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    final startLength = (maxLength - 3) ~/ 2;
    final endLength = maxLength - 3 - startLength;
    return '${text.substring(0, startLength)}...${text.substring(text.length - endLength)}';
  }
  
  @override
  Widget build(BuildContext context) {
    
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        hint: Row(
          children: [
            Icon(
              Icons.layers,
              size: 20,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        items: widget.items
            .map((String item) => DropdownMenuItem<String>(
                  value: item,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        if (item == 'Add custom asset') ...[
                          Icon(
                            Icons.add_circle_outline,
                            size: 18,
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(width: 10),
                        ] else if (item.contains(':')) ...[
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                item.split(':')[0].substring(0, min(3, item.split(':')[0].length)),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (item == 'Add custom asset')
                                Text(
                                  item,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                )
                              else if (item.contains(':')) ...[
                                Text(
                                  item.split(':')[0],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  _truncateMiddle(item.split(':')[1], 12),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ] else
                                Text(
                                  item,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ))
            .toList(),
        value: _selectedValue,
        onChanged: (String? value) {
          if (value != null) {
            setState(() {
              _selectedValue = value;
            });
            widget.onItemSelected(value);
          }
        },
        selectedItemBuilder: (BuildContext context) {
          return widget.items.map<Widget>((String item) {
            final displayText = item == 'Add custom asset' 
                ? item 
                : item.contains(':') 
                    ? item.split(':')[0]
                    : item;
            return Container(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(
                    item == 'Add custom asset' 
                        ? Icons.add_circle_outline
                        : Icons.token,
                    size: 20,
                    color: item == 'Add custom asset' 
                        ? Colors.blue.shade600
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      displayText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: item == 'Add custom asset' 
                            ? Colors.blue.shade700
                            : Colors.grey.shade800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList();
        },
        buttonStyleData: ButtonStyleData(
          height: 52,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
            color: Colors.white,
          ),
          elevation: 0,
        ),
        iconStyleData: IconStyleData(
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
          ),
          iconSize: 24,
          iconEnabledColor: Colors.grey.shade600,
          iconDisabledColor: Colors.grey.shade400,
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          offset: const Offset(0, -8),
          scrollbarTheme: ScrollbarThemeData(
            radius: const Radius.circular(20),
            thickness: WidgetStateProperty.all<double>(4),
            thumbVisibility: WidgetStateProperty.all<bool>(true),
            thumbColor: WidgetStateProperty.all<Color>(Colors.grey.shade400),
          ),
        ),
        menuItemStyleData: const MenuItemStyleData(
          height: 56,
          padding: EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }
}
