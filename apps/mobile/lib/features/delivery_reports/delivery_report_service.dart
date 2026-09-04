import 'package:drift/drift.dart';

import '../../data/local/riderbiz_database.dart';

class DeliveryReportLine {
  const DeliveryReportLine({
    required this.operatorId,
    required this.operatorName,
    required this.tariffId,
    required this.tariffVersion,
    required this.unitPriceMinor,
    required this.currency,
    required this.deliveredCount,
  });

  final String operatorId;
  final String operatorName;
  final String tariffId;
  final int tariffVersion;
  final int unitPriceMinor;
  final String currency;
  final int deliveredCount;

  int get totalMinor => unitPriceMinor * deliveredCount;
}

class DeliveryReport {
  const DeliveryReport({
    required this.periodStart,
    required this.periodEnd,
    required this.lines,
  });

  final DateTime periodStart;
  final DateTime periodEnd;
  final List<DeliveryReportLine> lines;

  int get deliveredCount =>
      lines.fold(0, (total, line) => total + line.deliveredCount);

  int totalMinorForCurrency(String currency) {
    final normalizedCurrency = currency.trim().toUpperCase();

    return lines
        .where((line) => line.currency == normalizedCurrency)
        .fold(0, (total, line) => total + line.totalMinor);
  }
}

class DeliveryReportService {
  DeliveryReportService(this.database);

  final RiderBizDatabase database;

  Future<DeliveryReport> daily(DateTime day) {
    final start = DateTime.utc(day.year, day.month, day.day);

    return forPeriod(start: start, end: start.add(const Duration(days: 1)));
  }

  Future<DeliveryReport> weekly(DateTime day) {
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);
    final start = normalizedDay.subtract(
      Duration(days: normalizedDay.weekday - DateTime.monday),
    );

    return forPeriod(start: start, end: start.add(const Duration(days: 7)));
  }

  Future<DeliveryReport> monthly({required int year, required int month}) {
    if (month < DateTime.january || month > DateTime.december) {
      throw ArgumentError.value(month, 'month');
    }

    final start = DateTime.utc(year, month);
    final end = month == DateTime.december
        ? DateTime.utc(year + 1)
        : DateTime.utc(year, month + 1);

    return forPeriod(start: start, end: end);
  }

  Future<DeliveryReport> forPeriod({
    required DateTime start,
    required DateTime end,
  }) async {
    final periodStart = start.toUtc();
    final periodEnd = end.toUtc();

    if (!periodEnd.isAfter(periodStart)) {
      throw ArgumentError('Report end must be after its start');
    }

    final packages =
        await (database.select(database.syntheticPackages)..where(
              (row) =>
                  row.status.equals('delivered') &
                  row.deliveredAt.isNotNull() &
                  row.deliveredAt.isBiggerOrEqualValue(periodStart) &
                  row.deliveredAt.isSmallerThanValue(periodEnd),
            ))
            .get();

    final operators = await database.select(database.logisticsOperators).get();
    final operatorNames = {
      for (final operator in operators) operator.id: operator.name,
    };

    final aggregates =
        <
          ({
            String operatorId,
            String tariffId,
            int tariffVersion,
            int unitPriceMinor,
            String currency,
          }),
          int
        >{};

    for (final package in packages) {
      final operatorId = package.identifiedOperatorId;
      final tariffId = package.tariffId;
      final tariffVersion = package.tariffVersionSnapshot;
      final unitPriceMinor = package.unitPriceMinorSnapshot;
      final currency = package.currencySnapshot;

      if (operatorId == null ||
          tariffId == null ||
          tariffVersion == null ||
          unitPriceMinor == null ||
          currency == null) {
        continue;
      }

      final key = (
        operatorId: operatorId,
        tariffId: tariffId,
        tariffVersion: tariffVersion,
        unitPriceMinor: unitPriceMinor,
        currency: currency,
      );

      aggregates.update(key, (count) => count + 1, ifAbsent: () => 1);
    }

    final lines =
        aggregates.entries
            .map(
              (entry) => DeliveryReportLine(
                operatorId: entry.key.operatorId,
                operatorName:
                    operatorNames[entry.key.operatorId] ??
                    'Operador desconocido',
                tariffId: entry.key.tariffId,
                tariffVersion: entry.key.tariffVersion,
                unitPriceMinor: entry.key.unitPriceMinor,
                currency: entry.key.currency,
                deliveredCount: entry.value,
              ),
            )
            .toList()
          ..sort((first, second) {
            final operatorComparison = first.operatorId.compareTo(
              second.operatorId,
            );

            if (operatorComparison != 0) {
              return operatorComparison;
            }

            return first.tariffVersion.compareTo(second.tariffVersion);
          });

    return DeliveryReport(
      periodStart: periodStart,
      periodEnd: periodEnd,
      lines: lines,
    );
  }
}
