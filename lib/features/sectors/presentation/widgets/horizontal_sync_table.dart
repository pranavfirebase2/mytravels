import 'package:flutter/material.dart';

class SyncScrollControllerGroup {
  final List<ScrollController> _controllers = [];
  double _offset = 0.0;
  bool _isScrolledByCode = false;

  ScrollController addAndGet() {
    final controller = ScrollController(initialScrollOffset: _offset);
    _controllers.add(controller);
    controller.addListener(() {
      if (_isScrolledByCode) return;
      if (controller.hasClients && controller.offset != _offset) {
        _isScrolledByCode = true;
        _offset = controller.offset;
        for (var c in _controllers) {
          if (c != controller && c.hasClients && c.offset != _offset) {
            c.jumpTo(_offset);
          }
        }
        _isScrolledByCode = false;
      }
    });
    return controller;
  }

  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
  }
}

class HorizontalSyncTable extends StatefulWidget {
  final Widget fixedHeader;
  final Widget scrollableHeader;
  final List<Widget> fixedRows;
  final List<Widget> scrollableRows;
  final double fixedColumnWidth;

  const HorizontalSyncTable({
    super.key,
    required this.fixedHeader,
    required this.scrollableHeader,
    required this.fixedRows,
    required this.scrollableRows,
    required this.fixedColumnWidth,
  });

  @override
  State<HorizontalSyncTable> createState() => _HorizontalSyncTableState();
}

class _HorizontalSyncTableState extends State<HorizontalSyncTable> {
  late SyncScrollControllerGroup _group;
  late ScrollController _headerController;
  late List<ScrollController> _rowControllers;

  @override
  void initState() {
    super.initState();
    _group = SyncScrollControllerGroup();
    _headerController = _group.addAndGet();
    _rowControllers = List.generate(widget.scrollableRows.length, (index) => _group.addAndGet());
  }

  @override
  void didUpdateWidget(HorizontalSyncTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollableRows.length != widget.scrollableRows.length) {
      _group.dispose();
      _group = SyncScrollControllerGroup();
      _headerController = _group.addAndGet();
      _rowControllers = List.generate(widget.scrollableRows.length, (index) => _group.addAndGet());
    }
  }

  @override
  void dispose() {
    _group.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: widget.fixedColumnWidth, child: widget.fixedHeader),
              Expanded(
                child: SingleChildScrollView(
                  controller: _headerController,
                  scrollDirection: Axis.horizontal,
                  child: widget.scrollableHeader,
                ),
              ),
            ],
          ),
        ),
        ...List.generate(widget.fixedRows.length, (index) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: widget.fixedColumnWidth, child: widget.fixedRows[index]),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _rowControllers[index],
                    scrollDirection: Axis.horizontal,
                    child: widget.scrollableRows[index],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
