import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simple_party_provider.dart';

class PendingProofsWidget extends StatelessWidget {
  const PendingProofsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_camera, size: 32, color: Colors.grey[400]),
            SizedBox(height: 8),
            Text(
              'Proof approval system updating...',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              'Will show pending proofs from party members',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}