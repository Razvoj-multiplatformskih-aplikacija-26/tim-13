import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

import '../dependencies.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _signOut(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Odjava još nije povezana.')));
  }

  @override
  Widget build(BuildContext context) {
    final owner = context.read<BackofficeDependencies>().owner;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: BlocBuilder<WorkOrdersBoardBloc, WorkOrdersBoardState>(
        builder: (context, state) => AccountView(
          user: owner,
          details: [
            if (state is BoardLoaded) ...[
              ('Radnici', '${state.book.fieldWorkers.length}'),
              ('Radni nalozi', '${state.book.orders.length}'),
              ('Čekaju potvrdu', '${state.book.ordersIn(WorkOrderStage.awaitingConfirmation).length}'),
            ],
          ],
          onSignOut: () => _signOut(context),
        ),
      ),
    );
  }
}
