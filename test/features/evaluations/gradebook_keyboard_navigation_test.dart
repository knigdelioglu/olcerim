import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olcerim/features/evaluations/presentation/gradebook_keyboard_navigation.dart';

void main() {
  group('gradebookCommandForKeyEvent', () {
    test('maps navigation and activation keys', () {
      expect(
        gradebookCommandForKeyEvent(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.arrowLeft,
            logicalKey: LogicalKeyboardKey.arrowLeft,
            timeStamp: Duration.zero,
          ),
        ),
        GradebookKeyboardCommand.moveLeft,
      );
      expect(
        gradebookCommandForKeyEvent(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.arrowDown,
            logicalKey: LogicalKeyboardKey.arrowDown,
            timeStamp: Duration.zero,
          ),
        ),
        GradebookKeyboardCommand.moveDown,
      );
      expect(
        gradebookCommandForKeyEvent(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.home,
            logicalKey: LogicalKeyboardKey.home,
            timeStamp: Duration.zero,
          ),
        ),
        GradebookKeyboardCommand.rowStart,
      );
      expect(
        gradebookCommandForKeyEvent(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.end,
            logicalKey: LogicalKeyboardKey.end,
            timeStamp: Duration.zero,
          ),
        ),
        GradebookKeyboardCommand.rowEnd,
      );
      expect(
        gradebookCommandForKeyEvent(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.enter,
            logicalKey: LogicalKeyboardKey.enter,
            timeStamp: Duration.zero,
          ),
        ),
        GradebookKeyboardCommand.activate,
      );
      expect(
        gradebookCommandForKeyEvent(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.space,
            logicalKey: LogicalKeyboardKey.space,
            timeStamp: Duration.zero,
          ),
        ),
        GradebookKeyboardCommand.activate,
      );
    });

    test('ignores key-up and repeated activation', () {
      expect(
        gradebookCommandForKeyEvent(
          const KeyUpEvent(
            physicalKey: PhysicalKeyboardKey.enter,
            logicalKey: LogicalKeyboardKey.enter,
            timeStamp: Duration.zero,
          ),
        ),
        GradebookKeyboardCommand.none,
      );
      expect(
        gradebookCommandForKeyEvent(
          const KeyRepeatEvent(
            physicalKey: PhysicalKeyboardKey.enter,
            logicalKey: LogicalKeyboardKey.enter,
            timeStamp: Duration.zero,
          ),
        ),
        GradebookKeyboardCommand.none,
      );
      expect(
        gradebookCommandForKeyEvent(
          const KeyRepeatEvent(
            physicalKey: PhysicalKeyboardKey.arrowRight,
            logicalKey: LogicalKeyboardKey.arrowRight,
            timeStamp: Duration.zero,
          ),
        ),
        GradebookKeyboardCommand.moveRight,
      );
    });
  });

  group('moveGradebookCell', () {
    const middle = GradebookCellPosition(row: 1, column: 1);

    test('moves in four directions', () {
      expect(
        moveGradebookCell(
          current: middle,
          command: GradebookKeyboardCommand.moveLeft,
          rowCount: 3,
          columnCount: 3,
        ),
        const GradebookCellPosition(row: 1, column: 0),
      );
      expect(
        moveGradebookCell(
          current: middle,
          command: GradebookKeyboardCommand.moveRight,
          rowCount: 3,
          columnCount: 3,
        ),
        const GradebookCellPosition(row: 1, column: 2),
      );
      expect(
        moveGradebookCell(
          current: middle,
          command: GradebookKeyboardCommand.moveUp,
          rowCount: 3,
          columnCount: 3,
        ),
        const GradebookCellPosition(row: 0, column: 1),
      );
      expect(
        moveGradebookCell(
          current: middle,
          command: GradebookKeyboardCommand.moveDown,
          rowCount: 3,
          columnCount: 3,
        ),
        const GradebookCellPosition(row: 2, column: 1),
      );
    });

    test('clamps movement at grid boundaries', () {
      expect(
        moveGradebookCell(
          current: const GradebookCellPosition(row: 0, column: 0),
          command: GradebookKeyboardCommand.moveUp,
          rowCount: 2,
          columnCount: 2,
        ),
        const GradebookCellPosition(row: 0, column: 0),
      );
      expect(
        moveGradebookCell(
          current: const GradebookCellPosition(row: 1, column: 1),
          command: GradebookKeyboardCommand.moveRight,
          rowCount: 2,
          columnCount: 2,
        ),
        const GradebookCellPosition(row: 1, column: 1),
      );
    });

    test('home and end move within the current student row', () {
      expect(
        moveGradebookCell(
          current: middle,
          command: GradebookKeyboardCommand.rowStart,
          rowCount: 4,
          columnCount: 5,
        ),
        const GradebookCellPosition(row: 1, column: 0),
      );
      expect(
        moveGradebookCell(
          current: middle,
          command: GradebookKeyboardCommand.rowEnd,
          rowCount: 4,
          columnCount: 5,
        ),
        const GradebookCellPosition(row: 1, column: 4),
      );
    });

    test('empty grids leave the current position untouched', () {
      expect(
        moveGradebookCell(
          current: middle,
          command: GradebookKeyboardCommand.moveDown,
          rowCount: 0,
          columnCount: 0,
        ),
        middle,
      );
    });
  });
}
