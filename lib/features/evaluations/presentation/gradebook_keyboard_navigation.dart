import 'package:flutter/services.dart';

/// Logical location of a score cell in the wide-screen gradebook.
class GradebookCellPosition {
  const GradebookCellPosition({required this.row, required this.column});

  final int row;
  final int column;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradebookCellPosition && row == other.row && column == other.column;

  @override
  int get hashCode => Object.hash(row, column);
}

enum GradebookKeyboardCommand {
  none,
  moveLeft,
  moveRight,
  moveUp,
  moveDown,
  rowStart,
  rowEnd,
  activate,
}

GradebookKeyboardCommand gradebookCommandForKeyEvent(KeyEvent event) {
  final isPress = event is KeyDownEvent || event is KeyRepeatEvent;
  if (!isPress) return GradebookKeyboardCommand.none;

  final key = event.logicalKey;
  if (key == LogicalKeyboardKey.arrowLeft) {
    return GradebookKeyboardCommand.moveLeft;
  }
  if (key == LogicalKeyboardKey.arrowRight) {
    return GradebookKeyboardCommand.moveRight;
  }
  if (key == LogicalKeyboardKey.arrowUp) {
    return GradebookKeyboardCommand.moveUp;
  }
  if (key == LogicalKeyboardKey.arrowDown) {
    return GradebookKeyboardCommand.moveDown;
  }
  if (key == LogicalKeyboardKey.home) {
    return GradebookKeyboardCommand.rowStart;
  }
  if (key == LogicalKeyboardKey.end) {
    return GradebookKeyboardCommand.rowEnd;
  }

  // Ignore repeats for activation so holding Enter/Space cannot stack dialogs.
  if (event is KeyDownEvent &&
      (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter ||
          key == LogicalKeyboardKey.space)) {
    return GradebookKeyboardCommand.activate;
  }

  return GradebookKeyboardCommand.none;
}

GradebookCellPosition moveGradebookCell({
  required GradebookCellPosition current,
  required GradebookKeyboardCommand command,
  required int rowCount,
  required int columnCount,
}) {
  if (rowCount <= 0 || columnCount <= 0) return current;

  final maxRow = rowCount - 1;
  final maxColumn = columnCount - 1;
  var row = current.row.clamp(0, maxRow);
  var column = current.column.clamp(0, maxColumn);

  switch (command) {
    case GradebookKeyboardCommand.moveLeft:
      column = (column - 1).clamp(0, maxColumn);
      break;
    case GradebookKeyboardCommand.moveRight:
      column = (column + 1).clamp(0, maxColumn);
      break;
    case GradebookKeyboardCommand.moveUp:
      row = (row - 1).clamp(0, maxRow);
      break;
    case GradebookKeyboardCommand.moveDown:
      row = (row + 1).clamp(0, maxRow);
      break;
    case GradebookKeyboardCommand.rowStart:
      column = 0;
      break;
    case GradebookKeyboardCommand.rowEnd:
      column = maxColumn;
      break;
    case GradebookKeyboardCommand.none:
    case GradebookKeyboardCommand.activate:
      break;
  }

  return GradebookCellPosition(row: row, column: column);
}
