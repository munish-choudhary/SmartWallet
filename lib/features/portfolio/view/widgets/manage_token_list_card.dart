import 'package:flutter/material.dart';

class ManageTokenListCard extends StatelessWidget {
  const ManageTokenListCard({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 68,
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1F),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFF2A292E),
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: Center(
                          child: Icon(
                            Icons.add_rounded,
                            size: 18,
                            color: Color(0xFFFFFFFF),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manage Token List',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.12,
                            color: Color(0xFFFFFFFF),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Customize displayed assets',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.07,
                            color: Color(0xFFC6C8B2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Color(0xFFC6C6C7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
