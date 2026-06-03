import 'package:flutter/material.dart';
import '../utils/responsive.dart';

class AdaptiveSplitLayout extends StatelessWidget {
  final Widget master;
  final Widget? detail;
  final double masterFlex;
  final double detailFlex;
  final Widget? placeholder;

  const AdaptiveSplitLayout({
    super.key,
    required this.master,
    this.detail,
    this.masterFlex = 3.5,
    this.detailFlex = 6.5,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);

    if (!isTablet) {
      return master;
    }

    return Row(
      children: [
        Expanded(
          flex: (masterFlex * 10).toInt(),
          child: master,
        ),
        VerticalDivider(width: 1, color: Colors.grey[200], thickness: 1),
        Expanded(
          flex: (detailFlex * 10).toInt(),
          child: detail ?? placeholder ?? Container(
            color: Colors.white,
            child: const Center(
              child: Text(
                'Pilih item untuk melihat detail',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
