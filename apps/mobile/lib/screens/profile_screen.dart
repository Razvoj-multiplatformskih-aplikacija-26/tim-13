import 'package:blocs/blocs.dart';
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
    final worker = context.read<AppDependencies>().worker;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: BlocBuilder<MyWorkOrdersBloc, MyWorkOrdersState>(
        builder: (context, state) => AccountView(
          user: worker,
          details: [
            if (state is MyWorkOrdersLoaded) ...[
              ('Aktivni nalozi', '${state.active.length}'),
              ('U istoriji', '${state.history.length}'),
            ],
          ],
          onSignOut: () => _signOut(context),
        ),
      ),
    );
  }
}
