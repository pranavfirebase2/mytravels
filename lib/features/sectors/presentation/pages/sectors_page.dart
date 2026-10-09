import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_layout.dart';

class SectorsPage extends StatelessWidget {
  const SectorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data mimicking the screenshot
    final sectors = [
      {'src': 'CCJ', 'dst': 'AAN', 'airlines': 'IX'},
      {'src': 'CCJ', 'dst': 'AUH', 'airlines': 'IX'},
      {'src': 'CCJ', 'dst': 'BAH', 'airlines': 'IX'},
      {'src': 'CCJ', 'dst': 'DMM', 'airlines': 'IX'},
      {'src': 'CCJ', 'dst': 'DOH', 'airlines': 'IX'},
      {'src': 'CCJ', 'dst': 'DXB', 'airlines': 'IX'},
      
      {'src': 'CCJ', 'dst': 'JED', 'airlines': 'QP'},
      {'src': 'CCJ', 'dst': 'KWI', 'airlines': 'IX'},
      {'src': 'CCJ', 'dst': 'MCT', 'airlines': 'OV · WY · IX'},
      {'src': 'CCJ', 'dst': 'RKT', 'airlines': 'IX'},
      {'src': 'CCJ', 'dst': 'RUH', 'airlines': 'IX · SV'},
      {'src': 'CCJ', 'dst': 'SHJ', 'airlines': 'IX · OV'},
      
      {'src': 'CCJ', 'dst': 'SLL', 'airlines': 'IX'},
      {'src': 'CNN', 'dst': 'AUH', 'airlines': 'IX'},
      {'src': 'CNN', 'dst': 'DOH', 'airlines': 'IX · 6E'},
      {'src': 'CNN', 'dst': 'DXB', 'airlines': 'IX'},
      {'src': 'CNN', 'dst': 'RKT', 'airlines': 'IX'},
      {'src': 'CNN', 'dst': 'RUH', 'airlines': 'IX'},
      
      {'src': 'CNN', 'dst': 'SHJ', 'airlines': 'IX'},
      {'src': 'COK', 'dst': 'AUH', 'airlines': 'IX · 6E'},
      {'src': 'COK', 'dst': 'DOH', 'airlines': 'QP · IX'},
      {'src': 'COK', 'dst': 'DXB', 'airlines': 'IX'},
      {'src': 'COK', 'dst': 'JED', 'airlines': 'SV'},
      {'src': 'COK', 'dst': 'RKT', 'airlines': '6E'},
    ];

    return AppLayout(
      activeRoute: '/sectors',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.white,
            ),
            onPressed: () {},
            child: const Text('Lowest Fare Search'),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 250,
              childAspectRatio: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: sectors.length,
            itemBuilder: (context, index) {
              final sector = sectors[index];
              return Card(
                color: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            sector['src']!,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Icon(Icons.arrow_forward_outlined, color: AppColors.textGrey, size: 20),
                          ),
                          Text(
                            sector['dst']!,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sector['airlines']!,
                        style: const TextStyle(color: AppColors.textGrey, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
