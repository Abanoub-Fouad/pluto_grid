import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:pluto_grid/pluto_grid.dart';

typedef PlutoOnLoadedEventCallback = void Function(
    PlutoGridOnLoadedEvent event);

typedef PlutoOnChangedEventCallback = void Function(
    PlutoGridOnChangedEvent event);

typedef PlutoOnSelectedEventCallback = void Function(
    PlutoGridOnSelectedEvent event);

typedef PlutoOnRowCheckedEventCallback = void Function(
    PlutoGridOnRowCheckedEvent event);

typedef PlutoOnRowDoubleTapEventCallback = void Function(
    PlutoGridOnRowDoubleTapEvent event);

typedef PlutoOnRowSecondaryTapEventCallback = void Function(
    PlutoGridOnRowSecondaryTapEvent event);

typedef PlutoOnRowsMovedEventCallback = void Function(
    PlutoGridOnRowsMovedEvent event);

typedef CreateHeaderCallBack = Widget Function(
    PlutoGridStateManager stateManager);

typedef CreateFooterCallBack = Widget Function(
    PlutoGridStateManager stateManager);

typedef PlutoRowColorCallback = Color Function(
    PlutoRowColorContext rowColorContext);

class PlutoGrid extends StatefulWidget {
  final List<PlutoColumn>? columns;

  final List<PlutoRow?>? rows;

  final List<PlutoColumnGroup>? columnGroups;

  final PlutoOnLoadedEventCallback? onLoaded;

  final PlutoOnChangedEventCallback? onChanged;

  final PlutoOnSelectedEventCallback? onSelected;

  final PlutoOnRowCheckedEventCallback? onRowChecked;

  final PlutoOnRowDoubleTapEventCallback? onRowDoubleTap;

  final PlutoOnRowSecondaryTapEventCallback? onRowSecondaryTap;

  final PlutoOnRowsMovedEventCallback? onRowsMoved;

  final CreateHeaderCallBack? createHeader;

  final CreateFooterCallBack? createFooter;

  final PlutoRowColorCallback? rowColorCallback;

  final PlutoGridConfiguration? configuration;

  /// [PlutoGridMode.normal]
  /// Normal grid with cell editing.
  ///
  /// [PlutoGridMode.select]
  /// Editing is not possible, and if you press enter or tap on the list,
  /// you can receive the selected row and cell from the onSelected callback.
  final PlutoGridMode? mode;

  const PlutoGrid({
    Key? key,
    required this.columns,
    required this.rows,
    this.columnGroups,
    this.onLoaded,
    this.onChanged,
    this.onSelected,
    this.onRowChecked,
    this.onRowDoubleTap,
    this.onRowSecondaryTap,
    this.onRowsMoved,
    this.createHeader,
    this.createFooter,
    this.rowColorCallback,
    this.configuration,
    this.mode = PlutoGridMode.normal,
  }) : super(key: key);

  @override
  _PlutoGridState createState() => _PlutoGridState();
}

class _PlutoGridState extends State<PlutoGrid> {
  FocusNode? gridFocusNode;

  LinkedScrollControllerGroup verticalScroll = LinkedScrollControllerGroup();

  LinkedScrollControllerGroup horizontalScroll = LinkedScrollControllerGroup();

  late PlutoGridStateManager stateManager;

  PlutoGridKeyManager? keyManager;

  PlutoGridEventManager? eventManager;

  bool? _showFrozenColumn;

  bool? _hasLeftFrozenColumns;

  double? _bodyLeftOffset;

  double? _bodyRightOffset;

  bool? _hasRightFrozenColumns;

  double? _rightFrozenLeftOffset;

  bool? _showColumnGroups;

  bool? _showColumnFilter;

  bool? _showLoading;

  Widget? _header;

  Widget? _footer;

  List<Function()> disposeList = [];

  @override
  void dispose() {
    for (var dispose in disposeList) {
      dispose();
    }

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    initProperties();

    initStateManager();

    initKeyManager();

    initEventManager();

    initOnLoadedEvent();

    initSelectMode();

    initHeaderFooter();
  }

  void initProperties() {
    gridFocusNode = FocusNode();

    // Dispose
    disposeList.add(() {
      gridFocusNode!.dispose();
    });
  }

  void initStateManager() {
    stateManager = PlutoGridStateManager(
      columns: widget.columns,
      rows: widget.rows,
      gridFocusNode: gridFocusNode,
      scroll: PlutoGridScrollController(
        vertical: verticalScroll,
        horizontal: horizontalScroll,
      ),
      columnGroups: widget.columnGroups,
      mode: widget.mode,
      onChangedEventCallback: widget.onChanged,
      onSelectedEventCallback: widget.onSelected,
      onRowCheckedEventCallback: widget.onRowChecked,
      onRowDoubleTapEventCallback: widget.onRowDoubleTap,
      onRowSecondaryTapEventCallback: widget.onRowSecondaryTap,
      onRowsMovedEventCallback: widget.onRowsMoved,
      createHeader: widget.createHeader,
      createFooter: widget.createFooter,
      configuration: widget.configuration,
    );

    stateManager.addListener(changeStateListener);

    stateManager.setRowColorCallback(widget.rowColorCallback);

    // Dispose
    disposeList.add(() {
      stateManager.removeListener(changeStateListener);
      stateManager.dispose();
    });
  }

  void initKeyManager() {
    keyManager = PlutoGridKeyManager(
      stateManager: stateManager,
    );

    keyManager!.init();

    stateManager.setKeyManager(keyManager);

    // Dispose
    disposeList.add(() {
      keyManager!.dispose();
    });
  }

  void initEventManager() {
    eventManager = PlutoGridEventManager(
      stateManager: stateManager,
    );

    eventManager!.init();

    stateManager.setEventManager(eventManager);

    // Dispose
    disposeList.add(() {
      eventManager!.dispose();
    });
  }

  void initOnLoadedEvent() {
    if (widget.onLoaded == null) {
      return;
    }

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      widget.onLoaded!(PlutoGridOnLoadedEvent(
        stateManager: stateManager,
      ));
    });
  }

  void initSelectMode() {
    if (widget.mode.isSelect != true) {
      return;
    }

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      if (stateManager.currentCell == null && widget.rows!.isNotEmpty) {
        stateManager.setCurrentCell(
            widget.rows!.first!.cells.entries.first.value, 0);
      }

      stateManager.gridFocusNode!.requestFocus();
    });
  }

  void initHeaderFooter() {
    if (stateManager.showHeader) {
      _header = stateManager.createHeader!(stateManager);
    }

    if (stateManager.showFooter) {
      _footer = stateManager.createFooter!(stateManager);
    }

    if (_header is PlutoPagination || _footer is PlutoPagination) {
      stateManager.setPage(1, notify: false);
    }
  }

  void changeStateListener() {
    if (_showFrozenColumn != stateManager.showFrozenColumn ||
        _hasLeftFrozenColumns != stateManager.hasLeftFrozenColumns ||
        _bodyLeftOffset != stateManager.bodyLeftOffset ||
        _bodyRightOffset != stateManager.bodyRightOffset ||
        _hasRightFrozenColumns != stateManager.hasRightFrozenColumns ||
        _rightFrozenLeftOffset != stateManager.rightFrozenLeftOffset ||
        _showColumnGroups != stateManager.showColumnGroups ||
        _showColumnFilter != stateManager.showColumnFilter ||
        _showLoading != stateManager.showLoading) {
      setState(resetState);
    }
  }

  KeyEventResult handleGridFocusOnKey(FocusNode focusNode, RawKeyEvent event) {
    /// 2021-11-19
    /// KeyEventResult.skipRemainingHandlers 동작 오류로 인한 임시 코드
    /// 이슈 해결 후 :
    /// ```dart
    /// keyManager!.subject.add(PlutoKeyManagerEvent(
    ///   focusNode: focusNode,
    ///   event: event,
    /// ));
    /// ```
    if (keyManager!.eventResult.isSkip == false) {
      keyManager!.subject.add(PlutoKeyManagerEvent(
        focusNode: focusNode,
        event: event,
      ));
    }

    /// 2021-11-19
    /// KeyEventResult.skipRemainingHandlers 동작 오류로 인한 임시 코드
    /// 이슈 해결 후 :
    /// ```dart
    /// return KeyEventResult.handled;
    /// ```
    return keyManager!.eventResult.consume(KeyEventResult.handled);
  }

  void setLayout(BoxConstraints size) {
    stateManager.setLayout(size);

    resetState();
  }

  void resetState() {
    _showFrozenColumn = stateManager.showFrozenColumn;

    _hasLeftFrozenColumns = stateManager.hasLeftFrozenColumns;

    _bodyLeftOffset = stateManager.bodyLeftOffset;

    _bodyRightOffset = stateManager.bodyRightOffset;

    _hasRightFrozenColumns = stateManager.hasRightFrozenColumns;

    _rightFrozenLeftOffset = stateManager.rightFrozenLeftOffset;

    _showColumnGroups = stateManager.showColumnGroups;

    _showColumnFilter = stateManager.showColumnFilter;

    _showLoading = stateManager.showLoading;
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      onFocusChange: stateManager.setKeepFocus,
      onKey: handleGridFocusOnKey,
      child: SafeArea(
        child: LayoutBuilder(
            key: stateManager.gridKey,
            builder: (ctx, size) {
              setLayout(size);

              if (stateManager.keepFocus) {
                gridFocusNode?.requestFocus();
              }

              final configuration = stateManager.configuration!;

              return Focus(
                focusNode: stateManager.gridFocusNode,
                child: ScrollConfiguration(
                  behavior: const PlutoScrollBehavior().copyWith(
                    scrollbars: false,
                  ),
                  child: Container(
                    padding:
                        const EdgeInsets.all(PlutoGridSettings.gridPadding),
                    decoration: BoxDecoration(
                      color: configuration.gridBackgroundColor,
                      borderRadius: configuration.gridBorderRadius,
                      border: Border.all(
                        color: configuration.gridBorderColor,
                        width: PlutoGridSettings.gridBorderWidth,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: configuration.gridBorderRadius
                          .resolve(TextDirection.ltr),
                      child: Column(
                        children: [
                          if (stateManager.showHeader)
                            _HeaderContainer(
                              header: _header!,
                              width: size.maxWidth,
                              height: stateManager.headerHeight,
                            ),
                          _ColumnRowContainer(
                            stateManager: stateManager,
                            showFrozenColumn: _showFrozenColumn!,
                            hasLeftFrozenColumns: _hasLeftFrozenColumns!,
                            hasRightFrozenColumns: _hasRightFrozenColumns!,
                          ),
                          if (stateManager.showFooter)
                            _FooterContainer(
                              footer: _footer!,
                              width: size.maxWidth,
                              height: stateManager.footerHeight,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
      ),
    );
  }
}

class _HeaderContainer extends StatelessWidget {
  final Widget header;

  final double width;

  final double height;

  const _HeaderContainer({
    required this.header,
    required this.width,
    required this.height,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: header,
    );
  }
}

class _ColumnRowContainer extends StatelessWidget {
  final PlutoGridStateManager stateManager;

  final bool showFrozenColumn;

  final bool hasLeftFrozenColumns;

  final bool hasRightFrozenColumns;

  const _ColumnRowContainer({
    required this.stateManager,
    required this.showFrozenColumn,
    required this.hasLeftFrozenColumns,
    required this.hasRightFrozenColumns,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: stateManager.configuration!.borderColor),
            bottom: BorderSide(color: stateManager.configuration!.borderColor),
          ),
        ),
        child: Row(
          children: [
            if (showFrozenColumn && hasLeftFrozenColumns)
              _LeftContainer(
                stateManager: stateManager,
                width: stateManager.leftFrozenColumnsWidth,
              ),
            Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: _BodyContainer(
                  stateManager: stateManager,
                ),
              ),
            ),
            if (showFrozenColumn && hasRightFrozenColumns)
              _RightContainer(
                stateManager: stateManager,
                width: stateManager.rightFrozenColumnsWidth,
              ),
          ],
        ),
      ),
    );
  }
}

class _LeftContainer extends StatelessWidget {
  final PlutoGridStateManager stateManager;

  final double width;

  const _LeftContainer({
    required this.stateManager,
    required this.width,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        children: [
          SizedBox(
            height: stateManager.columnGroupContainerHeight,
            child: PlutoLeftFrozenColumns(stateManager),
          ),
          Expanded(
            child: PlutoLeftFrozenRows(stateManager),
          ),
        ],
      ),
    );
  }
}

class _BodyContainer extends StatelessWidget {
  final PlutoGridStateManager stateManager;

  const _BodyContainer({
    required this.stateManager,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: stateManager.columnGroupContainerHeight,
          child: PlutoBodyColumns(stateManager),
        ),
        Expanded(
          child: PlutoBodyRows(stateManager),
        ),
      ],
    );
  }
}

class _RightContainer extends StatelessWidget {
  final PlutoGridStateManager stateManager;

  final double width;

  const _RightContainer({
    required this.stateManager,
    required this.width,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        children: [
          SizedBox(
            height: stateManager.columnGroupContainerHeight,
            child: PlutoRightFrozenColumns(stateManager),
          ),
          Expanded(
            child: PlutoRightFrozenRows(stateManager),
          ),
        ],
      ),
    );
  }
}

class _FooterContainer extends StatelessWidget {
  final Widget footer;

  final double width;

  final double height;

  const _FooterContainer({
    required this.footer,
    required this.width,
    required this.height,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: footer,
    );
  }
}

class PlutoGridOnLoadedEvent {
  final PlutoGridStateManager? stateManager;

  PlutoGridOnLoadedEvent({
    this.stateManager,
  });
}

/// Caution
///
/// [columnIdx] and [rowIdx] are values in the currently displayed state.
class PlutoGridOnChangedEvent {
  final int? columnIdx;
  final PlutoColumn? column;
  final int? rowIdx;
  final PlutoRow? row;
  final dynamic value;
  final dynamic oldValue;

  PlutoGridOnChangedEvent({
    this.columnIdx,
    this.column,
    this.rowIdx,
    this.row,
    this.value,
    this.oldValue,
  });

  @override
  String toString() {
    String out = '[PlutoOnChangedEvent] ';
    out += 'ColumnIndex : $columnIdx, RowIndex : $rowIdx\n';
    out += '::: oldValue : $oldValue\n';
    out += '::: newValue : $value';
    return out;
  }
}

class PlutoGridOnSelectedEvent {
  final PlutoRow? row;
  final PlutoCell? cell;

  PlutoGridOnSelectedEvent({
    this.row,
    this.cell,
  });
}

abstract class PlutoGridOnRowCheckedEvent {
  bool get isAll => runtimeType == PlutoGridOnRowCheckedAllEvent;
  bool get isRow => runtimeType == PlutoGridOnRowCheckedOneEvent;

  final PlutoRow? row;
  final bool? isChecked;

  PlutoGridOnRowCheckedEvent({
    this.row,
    this.isChecked,
  });
}

class PlutoGridOnRowDoubleTapEvent {
  final PlutoRow? row;
  final PlutoCell? cell;

  PlutoGridOnRowDoubleTapEvent({
    this.row,
    this.cell,
  });
}

class PlutoGridOnRowSecondaryTapEvent {
  final PlutoRow? row;
  final PlutoCell? cell;
  final Offset? offset;

  PlutoGridOnRowSecondaryTapEvent({
    this.row,
    this.cell,
    this.offset,
  });
}

class PlutoGridOnRowsMovedEvent {
  final int? idx;
  final List<PlutoRow?>? rows;

  PlutoGridOnRowsMovedEvent({
    required this.idx,
    required this.rows,
  });
}

class PlutoGridOnRowCheckedOneEvent extends PlutoGridOnRowCheckedEvent {
  PlutoGridOnRowCheckedOneEvent({
    PlutoRow? row,
    bool? isChecked,
  }) : super(row: row, isChecked: isChecked);
}

class PlutoGridOnRowCheckedAllEvent extends PlutoGridOnRowCheckedEvent {
  PlutoGridOnRowCheckedAllEvent({
    bool? isChecked,
  }) : super(row: null, isChecked: isChecked);
}

class PlutoGridSettings {
  /// If there is a frozen column, the minimum width of the body
  /// (if it is less than the value, the frozen column is released)
  static const double bodyMinWidth = 200.0;

  /// Default column width
  static const double columnWidth = 200.0;

  /// Column width
  static const double minColumnWidth = 80.0;

  /// Frozen column division line (ShadowLine) size
  static const double shadowLineSize = 3.0;

  /// Sum of frozen column division line width
  static const double totalShadowLineWidth =
      PlutoGridSettings.shadowLineSize * 2;

  /// Grid - padding
  static const double gridPadding = 2.0;

  /// Grid - border width
  static const double gridBorderWidth = 1.0;

  static const double gridInnerSpacing =
      (gridPadding * 2) + (gridBorderWidth * 2);

  /// Row - Default row height
  static const double rowHeight = 45.0;

  /// Row - border width
  static const double rowBorderWidth = 1.0;

  /// Row - total height
  static const double rowTotalHeight = rowHeight + rowBorderWidth;

  /// Cell - padding
  static const double cellPadding = 10;

  /// Column title - padding
  static const double columnTitlePadding = 10;

  /// Cell - fontSize
  static const double cellFontSize = 14;

  /// Scroll when multi-selection is as close as that value from the edge
  static const double offsetScrollingFromEdge = 10.0;

  /// Size that scrolls from the edge at once when selecting multiple
  static const double offsetScrollingFromEdgeAtOnce = 200.0;

  static const int debounceMillisecondsForColumnFilter = 300;
}

class PlutoScrollBehavior extends MaterialScrollBehavior {
  const PlutoScrollBehavior() : super();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

class PlutoRowColorContext {
  final PlutoRow row;

  final int rowIdx;

  final PlutoGridStateManager stateManager;

  PlutoRowColorContext({
    required this.row,
    required this.rowIdx,
    required this.stateManager,
  });
}

enum PlutoGridMode {
  normal,
  select,
  selectWithOneTap,
  popup,
}

extension PlutoGridModeExtension on PlutoGridMode? {
  bool get isNormal => this == PlutoGridMode.normal;

  bool get isSelect =>
      this == PlutoGridMode.select || this == PlutoGridMode.selectWithOneTap;

  bool get isSelectModeWithOneTap => this == PlutoGridMode.selectWithOneTap;

  bool get isPopup => this == PlutoGridMode.popup;
}
