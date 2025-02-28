// import 'package:flutter/material.dart';
// import '../features/common/utils/utils.dart';

// /// A widget that displays the status of a day with customizable appearance
// class DayStatus extends StatelessWidget {
//   final String date;
//   final String status;
//   final bool showDayLabel;
//   final double size;
//   final VoidCallback? onTap;

//   const DayStatus({
//     required this.date,
//     required this.status,
//     this.showDayLabel = true,
//     this.size = 40.0,
//     this.onTap,
//     Key? key,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final Color color = Utils.getStatusColor(status);

//     // Get the day abbreviation if needed
//     final String dayLabel = showDayLabel ? Utils.getDayAbbreviation(date) : '';

//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           if (showDayLabel)
//             Text(
//               dayLabel,
//               style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
//             ),
//           Container(
//             width: size,
//             height: size,
//             decoration: BoxDecoration(
//               color: color,
//               shape: BoxShape.circle,
//             ),
//             child: Center(
//               child: _getStatusIcon(status),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _getStatusIcon(String status) {
//     switch (status) {
//       case 'completed':
//         return const Icon(Icons.check, color: Colors.white);
//       case 'submitted':
//         return const Icon(Icons.hourglass_empty, color: Colors.white);
//       case 'skipped':
//         return const Icon(Icons.close, color: Colors.white);
//       case 'planned':
//         return const Icon(Icons.calendar_today, color: Colors.white);
//       default:
//         return const SizedBox();
//     }
//   }
// }
