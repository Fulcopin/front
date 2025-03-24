import 'package:flutter/material.dart';
import '../theme.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String description;
  final IconData icon;
  final String? trend;
  final bool isPositive;

  const StatsCard({
    Key? key,
    required this.title,
    required this.value,
    required this.description,
    required this.icon,
    this.trend,
    this.isPositive = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Icon(
                  icon,
                  color: AppTheme.mutedTextColor,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (trend != null) ...[
              const SizedBox(height: 8),
              Text(
                trend!,
                style: TextStyle(
                  color: isPositive ? AppTheme.successColor : AppTheme.errorColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

