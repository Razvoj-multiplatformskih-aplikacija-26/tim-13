import 'package:domain/domain.dart';

import 'serbian.dart';

extension DomainErrorMessage on DomainError {
  String get message => switch (this) {
    InvalidHectares() => 'Unesite površinu veću od nule, na primer 12,5.',
    InvalidFuelAmount() => 'Gorivo se unosi u litrima, od 0,01 do ${FuelLiters.max}.',
    InvalidMaterialQuantity() => 'Količina je ceo broj veći od nule.',
    ReasonRequired() => 'Razlog je obavezan.',
    ReasonTooLong() => 'Razlog može imati najviše ${ReasonText.maxLength} znakova.',
    InvalidInterval() => 'Kraj rada mora biti posle početka.',
    ExceedsParcelArea(:final remaining) => 'Na parceli je za ovu meru ostalo još ${formatHectares(remaining)}.',
    PreviousPhaseNotDone(:final required) => 'Prvo mora da se završi faza: ${required.label}.',
    InsufficientStock(:final missing) => 'Nema dovoljno zaliha u magacinu, nedostaje još $missing.',
    MaterialRequired() => 'Za ovu meru izaberite materijal iz magacina.',
    WorkerBusy() => 'Radnik u tom terminu već ima nalog.',
    MachineBusy() => 'Mašina je u tom terminu već zauzeta.',
    InvalidTransition() => 'Ova promena naloga nije moguća.',
    NotAllowed() => 'Nemate pravo na ovu radnju.',
    NotFound() => 'Nalog nije pronađen.',
  };
}
