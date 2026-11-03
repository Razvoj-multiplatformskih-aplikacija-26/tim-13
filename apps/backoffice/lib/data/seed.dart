import 'package:domain/domain.dart';

const gazda = User(id: UserId('u-gazda'), name: 'Stevan Ilić', role: Role.owner);
const marko = User(id: UserId('u-marko'), name: 'Marko Jovanović', role: Role.worker);
const janko = User(id: UserId('u-janko'), name: 'Janko Petrović', role: Role.worker);
const petar = User(id: UserId('u-petar'), name: 'Petar Savić', role: Role.worker);

const _imt = MachineId('m-t1');
const _deere = MachineId('m-t2');
const _fendt = MachineId('m-t3');
const _sprayer = MachineId('m-p1');
const _combine = MachineId('m-k1');

const _urea = StockItemId('s-urea');
const _npk = StockItemId('s-npk');
const _herbicide = StockItemId('s-herbicid');

const _reka = ParcelId('p-reka');
const _polje = ParcelId('p-polje');
const _salas = ParcelId('p-salas');
const _put = ParcelId('p-put');
const _ritovi = ParcelId('p-ritovi');
const _bara = ParcelId('p-bara');
const _humka = ParcelId('p-humka');

Hectares _ha(String value) => Hectares.parse(value).valueOrNull!;

ReasonText _reason(String value) => ReasonText.parse(value).valueOrNull!;

MaterialUse _use(StockItemId item, int quantity) => MaterialUse.parse(item, '$quantity').valueOrNull!;

final seedParcels = [
  Parcel(id: _reka, name: 'Njiva kod reke', area: _ha('12.5')),
  Parcel(id: _polje, name: 'Veliko polje', area: _ha('20')),
  Parcel(id: _salas, name: 'Salaš', area: _ha('8.4')),
  Parcel(id: _put, name: 'Kod puta', area: _ha('15')),
  Parcel(id: _ritovi, name: 'Ritovi', area: _ha('6.2')),
  Parcel(id: _bara, name: 'Bara', area: _ha('9.75')),
  Parcel(id: _humka, name: 'Humka', area: _ha('18')),
];

const seedWorkers = [marko, janko, petar];

const seedMachines = [
  Machine(id: _imt, name: 'Traktor IMT 577'),
  Machine(id: _deere, name: 'Traktor John Deere 6M'),
  Machine(id: _fendt, name: 'Traktor Fendt 720'),
  Machine(id: _sprayer, name: 'Prskalica Agromehanika'),
  Machine(id: _combine, name: 'Kombajn Claas Lexion'),
];

const seedStock = [
  StockItem(id: _urea, name: 'Urea', kind: StockKind.fertilizer, unit: StockUnit.kilogram, available: 5000),
  StockItem(id: _npk, name: 'NPK 15-15-15', kind: StockKind.fertilizer, unit: StockUnit.kilogram, available: 3000),
  StockItem(id: _herbicide, name: 'Herbicid Pulsar', kind: StockKind.chemical, unit: StockUnit.liter, available: 80),
];

List<WorkOrder> seedOrders(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);

  WorkInterval interval(int dayOffset, int startHour, int endHour) => WorkInterval.parse(
    start: today.add(Duration(days: dayOffset, hours: startHour)),
    end: today.add(Duration(days: dayOffset, hours: endHour)),
  ).valueOrNull!;

  WorkReport report(String hectares, String fuel, int dayOffset) => WorkReport(
    processed: _ha(hectares),
    fuel: FuelLiters.parse(fuel).valueOrNull!,
    submittedAt: today.add(Duration(days: dayOffset, hours: 18)),
  );

  WorkOrderStatus completed(String hectares, String fuel, int dayOffset) => Completed(
    report: report(hectares, fuel, dayOffset),
    approvedBy: gazda.id,
    at: today.add(Duration(days: dayOffset + 1, hours: 9)),
  );

  WorkOrder order(
    String id,
    ParcelId parcel,
    AgroOperation operation,
    WorkInterval when, {
    WorkOrderStatus status = const Planned(),
    User worker = marko,
    MachineId machine = _imt,
    MaterialUse? material,
  }) => WorkOrder(
    id: WorkOrderId(id),
    parcelId: parcel,
    operation: operation,
    workerId: worker.id,
    machineId: machine,
    interval: when,
    material: material,
    status: status,
  );

  return [
    order('n-01', _reka, AgroOperation.plowing, interval(-20, 7, 15), status: completed('12.5', '180', -20)),
    order(
      'n-02',
      _reka,
      AgroOperation.fertilizing,
      interval(-16, 7, 13),
      status: completed('12.5', '60', -16),
      material: _use(_urea, 600),
    ),
    order(
      'n-03',
      _reka,
      AgroOperation.seedbedPreparation,
      interval(-13, 7, 14),
      status: completed('12.5', '90', -13),
      worker: janko,
      machine: _deere,
    ),
    order('n-04', _reka, AgroOperation.sowing, interval(-10, 7, 14), status: completed('12.5', '70', -10)),
    order('n-05', _reka, AgroOperation.spraying, interval(1, 7, 10), machine: _sprayer, material: _use(_herbicide, 60)),
    order('n-06', _polje, AgroOperation.plowing, interval(-15, 7, 17), status: completed('20', '280', -15)),
    order(
      'n-07',
      _polje,
      AgroOperation.fertilizing,
      interval(-2, 7, 15),
      status: AwaitingConfirmation(report: report('12', '75', -2)),
      material: _use(_urea, 700),
    ),
    order(
      'n-08',
      _polje,
      AgroOperation.fertilizing,
      interval(-5, 7, 12),
      status: completed('5', '30', -5),
      worker: janko,
      machine: _deere,
      material: _use(_urea, 300),
    ),
    order('n-09', _polje, AgroOperation.sowing, interval(2, 7, 15)),
    order(
      'n-10',
      _salas,
      AgroOperation.plowing,
      interval(-3, 7, 13),
      status: Rejected(
        report: report('8', '400', -3),
        reason: _reason('Utrošak goriva je pogrešno unet.'),
        rejectedBy: gazda.id,
        at: today.add(const Duration(days: -2, hours: 9)),
      ),
    ),
    order('n-11', _salas, AgroOperation.fertilizing, interval(3, 7, 12), material: _use(_urea, 400)),
    order(
      'n-12',
      _put,
      AgroOperation.plowing,
      interval(0, 7, 16),
      status: InProgress(startedAt: today.add(const Duration(hours: 7))),
    ),
    order(
      'n-13',
      _put,
      AgroOperation.fertilizing,
      interval(-1, 7, 12),
      status: Cancelled(
        reason: _reason('Jaka kiša, zemljište je preterano vlažno.'),
        cancelledBy: marko.id,
        at: today.add(const Duration(days: -1, hours: 6)),
      ),
      material: _use(_urea, 500),
    ),
    order('n-14', _ritovi, AgroOperation.plowing, interval(1, 11, 14)),
    order('n-15', _polje, AgroOperation.fertilizing, interval(1, 15, 18), material: _use(_urea, 150)),
    order(
      'n-16',
      _bara,
      AgroOperation.plowing,
      interval(-9, 7, 14),
      status: completed('9.75', '130', -9),
      worker: petar,
      machine: _fendt,
    ),
    order(
      'n-17',
      _bara,
      AgroOperation.fertilizing,
      interval(-6, 7, 12),
      status: AwaitingConfirmation(report: report('9.75', '45', -6)),
      worker: petar,
      machine: _fendt,
      material: _use(_npk, 480),
    ),
    order(
      'n-18',
      _humka,
      AgroOperation.plowing,
      interval(-12, 7, 17),
      status: completed('18', '240', -12),
      worker: petar,
      machine: _fendt,
    ),
    order(
      'n-19',
      _humka,
      AgroOperation.fertilizing,
      interval(-8, 7, 15),
      status: completed('18', '95', -8),
      worker: janko,
      machine: _deere,
      material: _use(_npk, 900),
    ),
    order(
      'n-20',
      _humka,
      AgroOperation.seedbedPreparation,
      interval(-1, 7, 15),
      status: AwaitingConfirmation(report: report('18', '110', -1)),
      worker: petar,
      machine: _fendt,
    ),
    order('n-21', _humka, AgroOperation.sowing, interval(4, 7, 16), worker: petar, machine: _fendt),
    order(
      'n-22',
      _ritovi,
      AgroOperation.fertilizing,
      interval(5, 7, 11),
      worker: janko,
      machine: _deere,
      material: _use(_urea, 300),
    ),
    order(
      'n-23',
      _bara,
      AgroOperation.seedbedPreparation,
      interval(0, 8, 15),
      status: Cancelled(
        reason: _reason('Kvar na tanjiraču.'),
        cancelledBy: gazda.id,
        at: today.add(const Duration(hours: 7)),
      ),
      worker: janko,
      machine: _deere,
    ),
    order('n-24', _put, AgroOperation.fertilizing, interval(6, 7, 13), worker: petar, material: _use(_npk, 700)),
  ];
}
