import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

class WorkReportScreen extends StatelessWidget {
  const WorkReportScreen({super.key, required this.order, required this.book});

  final WorkOrder order;
  final WorkBook book;

  void _onStateChanged(BuildContext context, WorkReportFormState state) {
    final messenger = ScaffoldMessenger.of(context);
    switch (state) {
      case WorkReportFormSucceeded():
        context.read<MyWorkOrdersBloc>().add(const MyWorkOrdersRefreshed());
        messenger.showSnackBar(const SnackBar(content: Text('Izveštaj je poslat. Čeka potvrdu gazde.')));
        context.pop();
      case WorkReportFormRejected(:final error):
        messenger.showSnackBar(SnackBar(content: Text(error.message)));
      case WorkReportFormFailed():
        messenger.showSnackBar(const SnackBar(content: Text('Izveštaj nije poslat. Pokušajte ponovo.')));
      case WorkReportFormEditing() || WorkReportFormSubmitting():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<WorkReportFormBloc>();
    final material = order.material;
    final item = material == null ? null : book.stockItem(material.item);
    return BlocConsumer<WorkReportFormBloc, WorkReportFormState>(
      listener: _onStateChanged,
      builder: (context, state) {
        final submitting = state is WorkReportFormSubmitting;
        final errors = state is WorkReportFormEditing ? state : null;
        return Scaffold(
          appBar: AppBar(title: const Text('Izveštaj sa terena')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    spacing: 14,
                    children: [
                      OperationIcon(operation: order.operation, stage: order.status.stage),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 2,
                          children: [
                            Text(
                              '${order.operation.label}, ${book.parcelOf(order)?.name ?? ''}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              'Preostalo za ovu meru: ${formatHectares(bloc.remaining)}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                key: const Key('hectares'),
                enabled: !submitting,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Obrađena površina (ha)',
                  errorText: errors?.hectaresError?.message,
                  errorMaxLines: 2,
                ),
                onChanged: (text) => bloc.add(WorkReportHectaresChanged(text)),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('fuel'),
                enabled: !submitting,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: item == null ? TextInputAction.done : TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Utrošeno gorivo (l)',
                  errorText: errors?.fuelError?.message,
                  errorMaxLines: 2,
                ),
                onChanged: (text) => bloc.add(WorkReportFuelChanged(text)),
              ),
              if (item != null) ...[
                const SizedBox(height: 16),
                TextField(
                  key: const Key('material'),
                  enabled: !submitting,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: '${item.name} (${item.unit.label})',
                    errorText: errors?.materialError?.message,
                    errorMaxLines: 2,
                  ),
                  onChanged: (text) => bloc.add(WorkReportMaterialChanged(text)),
                ),
              ],
            ],
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: submitting ? null : () => bloc.add(const WorkReportSubmitted()),
              child: submitting
                  ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Text('Pošalji izveštaj'),
            ),
          ),
        );
      },
    );
  }
}
