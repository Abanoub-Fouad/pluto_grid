import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';

import '../model/context/context_widget.dart';

class PlutoBaseRow extends StatelessWidget
    with ContextWidget<PlutoRow, PlutoBaseRow> {
  final PlutoGridStateManager stateManager;
  final int rowIdx;
  final PlutoRow row;
  final List<PlutoColumn> columns;

  PlutoBaseRow({
    required this.stateManager,
    required this.rowIdx,
    required this.row,
    required this.columns,
    Key? key,
  }) : super(key: key);

  get model => row;

  @override
  Widget build(BuildContext context) {
    return DragTarget(
      onWillAccept: (List<PlutoRow?>? draggingRows) {
        if (draggingRows == null || draggingRows.isEmpty) {
          return false;
        }

        final selectedRows = stateManager.currentSelectingRows.isNotEmpty
            ? stateManager.currentSelectingRows
            : draggingRows;

        return selectedRows.firstWhere(
              (element) => element?.key == row.key,
              orElse: () => null,
            ) ==
            null;
      },
      onMove: (DragTargetDetails details) async {
        final draggingRows = stateManager.currentSelectingRows.isNotEmpty
            ? stateManager.currentSelectingRows
            : details.data as List<PlutoRow?>;

        stateManager.eventManager!.addEvent(
          PlutoGridDragRowsEvent(
            rows: draggingRows,
            targetIdx: rowIdx,
            offset: details.offset,
          ),
        );
      },
      builder: (dragContext, candidate, rejected) {
        return _RowContainerWidget(
          stateManager: stateManager,
          rowIdx: rowIdx,
          row: row,
          columns: columns,
          child: Row(
            children: columns.map((column) {
              return PlutoBaseCell(
                key: row.cells[column.field]!.key,
                stateManager: stateManager,
                cell: row.cells[column.field]!,
                width: column.width,
                height: stateManager.rowHeight,
                column: column,
                rowIdx: rowIdx,
                row: row,
              );
            }).toList(growable: false),
          ),
          updateContext: updateContext,
        );
      },
    );
  }
}

class _RowContainerWidget extends PlutoStatefulWidget {
  final PlutoGridStateManager stateManager;
  final int rowIdx;
  final PlutoRow row;
  final List<PlutoColumn> columns;
  final Widget child;
  final void Function() updateContext;

  _RowContainerWidget({
    required this.stateManager,
    required this.rowIdx,
    required this.row,
    required this.columns,
    required this.child,
    required this.updateContext,
  });

  @override
  __RowContainerWidgetState createState() => __RowContainerWidgetState();
}

abstract class __RowContainerWidgetStateWithChangeKeepAlive
    extends PlutoStateWithChangeKeepAlive<_RowContainerWidget> {
  bool? isCurrentRow;

  bool? isSelectedRow;

  bool? isSelecting;

  bool? isCheckedRow;

  bool? isDragTarget;

  bool? isTopDragTarget;

  bool? isBottomDragTarget;

  bool? hasCurrentSelectingPosition;

  bool? hasFocus;

  Color? rowColor;

  @override
  void onChange() {
    resetState((update) {
      isCurrentRow = update<bool?>(
        isCurrentRow,
        widget.stateManager.currentRowIdx == widget.rowIdx,
      );

      isSelectedRow = update<bool?>(
        isSelectedRow,
        widget.stateManager.isSelectedRow(widget.row.key),
      );

      isSelecting = update<bool?>(isSelecting, widget.stateManager.isSelecting);

      isCheckedRow = update<bool?>(isCheckedRow, widget.row.checked);

      final alreadyTarget = widget.stateManager.dragRows?.firstWhere(
              (element) => element?.key == widget.row.key,
              orElse: () => null) !=
          null;

      isDragTarget = update<bool?>(
        isDragTarget,
        !alreadyTarget && widget.stateManager.isRowIdxDragTarget(widget.rowIdx),
      );

      isTopDragTarget = update<bool?>(
        isTopDragTarget,
        widget.stateManager.isRowIdxTopDragTarget(widget.rowIdx),
      );

      isBottomDragTarget = update<bool?>(
        isBottomDragTarget,
        widget.stateManager.isRowIdxBottomDragTarget(widget.rowIdx),
      );

      hasCurrentSelectingPosition = update<bool?>(
        hasCurrentSelectingPosition,
        widget.stateManager.hasCurrentSelectingPosition,
      );

      hasFocus = update<bool?>(
        hasFocus,
        isCurrentRow! && widget.stateManager.hasFocus,
      );

      rowColor = update<Color?>(rowColor, getRowColor());

      if (changed) {
        widget.updateContext();
      }

      if (widget.stateManager.mode.isNormal) {
        setKeepAlive(widget.stateManager.isRowBeingDragged(widget.row.key));
      }
    });
  }

  Color getDefaultRowColor() {
    if (widget.stateManager.rowColorCallback == null) {
      return widget.stateManager.configuration!.gridBackgroundColor;
    }

    return widget.stateManager.rowColorCallback!(
      PlutoRowColorContext(
        rowIdx: widget.rowIdx,
        row: widget.row,
        stateManager: widget.stateManager,
      ),
    );
  }

  Color getRowColor() {
    final Color defaultColor = getDefaultRowColor();

    if (isDragTarget!)
      return widget.stateManager.configuration!.cellColorInReadOnlyState;

    final bool checkCurrentRow =
        isCurrentRow! && (!isSelecting! && !hasCurrentSelectingPosition!);

    final bool checkSelectedRow =
        widget.stateManager.isSelectedRow(widget.row.key);

    if (!checkCurrentRow && !checkSelectedRow) {
      return defaultColor;
    }

    if (widget.stateManager.selectingMode.isRow) {
      return checkSelectedRow
          ? widget.stateManager.configuration!.activatedColor
          : defaultColor;
    }

    if (!hasFocus!) {
      return defaultColor;
    }

    return checkCurrentRow
        ? widget.stateManager.configuration!.activatedColor
        : defaultColor;
  }
}

class __RowContainerWidgetState
    extends __RowContainerWidgetStateWithChangeKeepAlive {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    final decoration = BoxDecoration(
      color: isCheckedRow!
          ? Color.alphaBlend(
              widget.stateManager.configuration!.checkedColor,
              rowColor!,
            )
          : rowColor,
      border: Border(
        top: isTopDragTarget!
            ? BorderSide(
                width: PlutoGridSettings.rowBorderWidth,
                color: widget.stateManager.configuration!.activatedBorderColor,
              )
            : BorderSide.none,
        bottom: BorderSide(
          width: PlutoGridSettings.rowBorderWidth,
          color: isBottomDragTarget!
              ? widget.stateManager.configuration!.activatedBorderColor
              : widget.stateManager.configuration!.borderColor,
        ),
      ),
    );

    return _AnimatedOrNormalContainer(
      enable: widget.stateManager.configuration!.enableRowColorAnimation,
      child: widget.child,
      decoration: decoration,
    );
  }
}

class _AnimatedOrNormalContainer extends StatelessWidget {
  final bool enable;

  final Widget child;

  final BoxDecoration decoration;

  const _AnimatedOrNormalContainer({
    required this.enable,
    required this.child,
    required this.decoration,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return enable
        ? AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: decoration,
            child: child,
          )
        : Container(
            decoration: decoration,
            child: child,
          );
  }
}
