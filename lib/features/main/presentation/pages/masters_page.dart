import 'package:flutter/material.dart';
import 'master_management_modal.dart';

class MastersPage extends StatelessWidget {
  const MastersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MasterManagementModal(
      fullPage: true,
      onMasterUpdated: () {},
    );
  }
}
