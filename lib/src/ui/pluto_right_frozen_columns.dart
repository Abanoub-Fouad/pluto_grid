import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';

class PlutoRightFrozenColumns extends PlutoStatefulWidget {
  @override
  final PlutoGridStateManager stateManager;

  const PlutoRightFrozenColumns(
    this.stateManager, {
    Key? key,
  }) : super(key: key);

  @override
  _PlutoRightFrozenColumnsState createState() =>
      _PlutoRightFrozenColumnsState();
}

abstract class _PlutoRightFrozenColumnsStateWithChange
    extends PlutoStateWithChange<PlutoRightFrozenColumns> {
  bool? showColumnGroups;

  List<PlutoColumn>? columns;

  List<PlutoColumnGroupPair>? columnGroups;

  int? itemCount;

  double? width;

  @override
  void onChange() {
    resetState((update) {
      showColumnGroups = update<bool?>(
        showColumnGroups,
        widget.stateManager.showColumnGroups,
      );

      columns = update<List<PlutoColumn>?>(
        columns,
        widget.stateManager.rightFrozenColumns,
        compare: listEquals,
      );

      if (changed && showColumnGroups == true) {
        columnGroups = widget.stateManager.separateLinkedGroup(
          columnGroupList: widget.stateManager.refColumnGroups!,
          columns: columns!,
        );
      }

      itemCount = update<int?>(itemCount, _getItemCount());

      width = update<double?>(
        width,
        widget.stateManager.rightFrozenColumnsWidth,
      );
    });
  }

  int _getItemCount() {
    return showColumnGroups == true ? columnGroups!.length : columns!.length;
  }
}

class _PlutoRightFrozenColumnsState
    extends _PlutoRightFrozenColumnsStateWithChange {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: widget.stateManager.columnGroupContainerHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (ctx, i) {
          return showColumnGroups == true
              ? PlutoBaseColumnGroup(
                  stateManager: widget.stateManager,
                  columnGroup: columnGroups![i],
                  depth: widget.stateManager.columnGroupDepth(
                    widget.stateManager.refColumnGroups!,
                  ),
                )
              : PlutoBaseColumn(
                  stateManager: widget.stateManager,
                  column: columns![i],
                );
        },
      ),
    );
  }
}
