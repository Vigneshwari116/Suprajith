import 'package:flutter/material.dart';

/// Spreadsheet-like bordered table for workstation lists.
class ExcelStyleTable extends StatelessWidget {
  const ExcelStyleTable({
    super.key,
    required this.columns,
    required this.rows,
    this.columnWidths,
    this.emptyMessage = 'No rows to display.',
  });

  final List<String> columns;
  final List<List<String>> rows;
  final List<double>? columnWidths;
  final String emptyMessage;

  static const _borderColor = Color(0xFF94A3B8);
  static const _headerBg = Color(0xFFE2E8F0);
  static const _rowBg = Colors.white;
  static const _altRowBg = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        child: Text(emptyMessage, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
      );
    }

    final widths = <int, TableColumnWidth>{};
    for (var i = 0; i < columns.length; i++) {
      final w = columnWidths != null && i < columnWidths!.length ? columnWidths![i] : null;
      widths[i] = w != null ? FixedColumnWidth(w) : const IntrinsicColumnWidth();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: SingleChildScrollView(
              child: Table(
                border: TableBorder.all(color: _borderColor, width: 1),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                columnWidths: widths,
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: _headerBg),
                    children: columns
                        .map(
                          (label) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  ...List.generate(rows.length, (index) {
                    final cells = rows[index];
                    final bg = index.isEven ? _rowBg : _altRowBg;
                    return TableRow(
                      decoration: BoxDecoration(color: bg),
                      children: List.generate(columns.length, (col) {
                        final text = col < cells.length ? cells[col] : '';
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Text(
                            text,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontFamily: 'Consolas',
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        );
                      }),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
