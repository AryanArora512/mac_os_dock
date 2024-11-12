import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Dock(
            initialItems: const [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo,
            ],
            builder: (icon, isDragging) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                constraints: const BoxConstraints(minWidth: 48),
                height: isDragging ? 60 : 48,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors
                      .primaries[icon.hashCode % Colors.primaries.length]
                      .withOpacity(isDragging ? 0.8 : 1.0),
                  boxShadow: isDragging
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: Icon(icon,
                      color: Colors.white, size: isDragging ? 30 : 24),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class Dock<T> extends StatefulWidget {
  const Dock({
    super.key,
    required this.initialItems,
    required this.builder,
  });

  final List<T> initialItems;
  final Widget Function(T item, bool isDragging) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

class _DockState<T> extends State<Dock<T>> {
  late List<T> _items;
  final ValueNotifier<int?> _draggingIndex = ValueNotifier<int?>(null);
  final ValueNotifier<bool> _isDraggingOut = ValueNotifier<bool>(false);

  final GlobalKey _dockKey = GlobalKey(); // GlobalKey for Dock container

  @override
  void initState() {
    super.initState();
    _items = widget.initialItems.toList();
  }

  @override
  void dispose() {
    _draggingIndex.dispose();
    _isDraggingOut.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _dockKey, // Assign GlobalKey to the container
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black12,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return ValueListenableBuilder<int?>(
            valueListenable: _draggingIndex,
            builder: (context, draggingIndex, child) {
              final isDragging = index == draggingIndex;

              return Draggable<int>(
                data: index,
                feedback: Transform.scale(
                  scale: 1.2,
                  child: widget.builder(item, true),
                ),
                childWhenDragging: ValueListenableBuilder<bool>(
                  valueListenable: _isDraggingOut,
                  builder: (context, isDraggingOut, child) {
                    return isDraggingOut ? const SizedBox() : child!;
                  },
                  child: widget.builder(item, false),
                ),
                onDragStarted: () {
                  _draggingIndex.value = index;
                },
                onDragUpdate: (details) {
                  final dockRenderBox =
                      _dockKey.currentContext?.findRenderObject() as RenderBox?;

                  if (dockRenderBox != null) {
                    final dockOffset = dockRenderBox.localToGlobal(Offset.zero);
                    final dockWidth = dockRenderBox.size.width;
                    final dragX = details.globalPosition.dx;
                    final dragY = details.globalPosition.dy;

                    final isOutOfBoundsTop = dragY < dockOffset.dy;
                    final isOutOfBoundsBottom =
                        dragY > dockOffset.dy + dockRenderBox.size.height;

                    if (isOutOfBoundsTop || isOutOfBoundsBottom) {
                      if (!_isDraggingOut.value) {
                        _isDraggingOut.value = true;
                      }
                    } else {
                      if (_isDraggingOut.value) {
                        _isDraggingOut.value = false;
                      }

                      if (dragX >= dockOffset.dx &&
                          dragX <= dockOffset.dx + dockWidth) {
                        final localDragPosition = dragX - dockOffset.dx;
                        final targetIndex = _getTargetIndex(localDragPosition);

                        if (targetIndex != draggingIndex) {
                          setState(() {
                            _swapItems(draggingIndex ?? 0, targetIndex);
                          });
                          _draggingIndex.value = targetIndex;
                        }
                      }
                    }
                  }
                },
                onDragEnd: (_) {
                  _draggingIndex.value = null;
                  _isDraggingOut.value = false;
                },
                child: DragTarget<int>(
                  onAcceptWithDetails: (fromIndex) {
                    if (fromIndex.data != index) {
                      setState(() {
                        final draggedItem = _items.removeAt(fromIndex.data);
                        if (fromIndex.data < index) {
                          _items.insert(index, draggedItem);
                        } else {
                          _items.insert(index + 1, draggedItem);
                        }
                        _isDraggingOut.value = false;
                      });
                    }
                  },
                  builder: (context, candidateData, rejectedData) {
                    return widget.builder(item, isDragging);
                  },
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  int _getTargetIndex(double dragPosition) {
    const double itemWidth = 48.0;
    const double padding = 16.0;
    const double halfItemWidth = itemWidth / 2;
    double currentOffset = 0.0;

    int nearestIndex = 0;
    double nearestDistance = double.infinity;

    for (int i = 0; i < _items.length; i++) {
      double itemCenter = currentOffset + halfItemWidth;
      double distance = (dragPosition - itemCenter).abs();

      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestIndex = i;
      }

      currentOffset += itemWidth + padding;
    }

    return nearestIndex;
  }

  void _swapItems(int fromIndex, int toIndex) {
    if (fromIndex != toIndex) {
      final item = _items.removeAt(fromIndex);
      _items.insert(toIndex, item);
    }
  }
}
