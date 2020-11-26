part of '../../pluto_grid.dart';

class PlutoLeftFrozenRows extends StatefulWidget {
  final PlutoStateManager stateManager;

  PlutoLeftFrozenRows(this.stateManager);

  @override
  _PlutoLeftFrozenRowsState createState() => _PlutoLeftFrozenRowsState();
}

class _PlutoLeftFrozenRowsState extends State<PlutoLeftFrozenRows> {
  List<PlutoColumn> _columns;

  List<PlutoRow> _rows;

  ScrollController scroll;

  @override
  void dispose() {
    scroll.dispose();

    widget.stateManager.removeListener(changeStateListener);

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _columns = widget.stateManager.leftFrozenColumns;

    _rows = widget.stateManager.rows;

    scroll = widget.stateManager.scroll.vertical.addAndGet();

    widget.stateManager.addListener(changeStateListener);
  }

  void changeStateListener() {
    if (listEquals(_columns, widget.stateManager.leftFrozenColumns) == false ||
        listEquals(_rows, widget.stateManager._rows) == false) {
      setState(() {
        _columns = widget.stateManager.leftFrozenColumns;
        _rows = widget.stateManager.rows;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scroll,
      scrollDirection: Axis.vertical,
      itemCount: _rows.length,
      itemExtent: widget.stateManager.rowTotalHeight,
      itemBuilder: (ctx, i) {
        return PlutoBaseRow(
          key: ValueKey('left_frozen_row_${_rows[i]._key}'),
          stateManager: widget.stateManager,
          rowIdx: i,
          row: _rows[i],
          columns: _columns,
        );
      },
    );
  }
}