import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  runApp(const DockApp());
}

class DockApp extends StatelessWidget {
  const DockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Container(
            height: 75,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.black12,
            ),
            padding: const EdgeInsets.all(4),
            child: const Dock(),
          ),
        ),
      ),
    );
  }
}

class DockController extends GetxController {
  final RxList<IconData> dockItems = <IconData>[
    Icons.person,
    Icons.message,
    Icons.call,
    Icons.camera,
    Icons.photo
  ].obs;

  final RxnInt draggingIndex = RxnInt();
  final RxnInt placeholderIndex = RxnInt();
  final RxnInt hoveredIndex = RxnInt();

  void setDraggingIndex(int? index) => draggingIndex.value = index;
  void setPlaceholderIndex(int? index) => placeholderIndex.value = index;
  void setHoveredIndex(int? index) => hoveredIndex.value = index;

  void updateDockItems(int draggedIndex, int targetIndex, IconData data) {
    if (draggedIndex < 0 ||
        draggedIndex >= dockItems.length ||
        targetIndex < 0 ||
        targetIndex > dockItems.length) return;

    dockItems.removeAt(draggedIndex);
    dockItems.insert(targetIndex, data);
  }

  void resetDragState() {
    setDraggingIndex(null);
    setPlaceholderIndex(null);
    setHoveredIndex(null);
  }
}

class Dock extends StatelessWidget {
  const Dock({super.key});

  @override
  Widget build(BuildContext context) {
    final DockController controller = Get.put(DockController());

    return SizedBox(
      height: 100,
      child: Obx(() => Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int index = 0; index < controller.dockItems.length; index++) ...[
            if (controller.draggingIndex.value != null &&
                controller.placeholderIndex.value == index)
              _buildPlaceholderWidget(index, controller),
            if (controller.draggingIndex.value != index)
              _buildDraggableDockButton(index, controller),
          ],
        ],
      )),
    );
  }

  Widget _buildDraggableDockButton(int index, DockController controller) {
    final IconData icon = controller.dockItems[index];

    return MouseRegion(
      onEnter: (_) => controller.setHoveredIndex(index),
      onExit: (_) => controller.setHoveredIndex(null),
      child: Draggable<IconData>(
        data: icon,
        feedback: Material(
          color: Colors.transparent,
          child: Transform.scale(
            scale: 1.2,
            child: _buildButton(icon, hovered: false, controller: controller),
          ),
        ),
        childWhenDragging: const SizedBox(width: 70),
        onDragStarted: () {
          controller.setDraggingIndex(index);
          controller.setPlaceholderIndex(index);
        },
        onDragCompleted: () => controller.resetDragState(),
        onDraggableCanceled: (_, __) => controller.resetDragState(),
        child: DragTarget<IconData>(
          onWillAcceptWithDetails: (details) {
            controller.setPlaceholderIndex(index);
            return true;
          },
          onAcceptWithDetails: (details) {
            final int draggedIndex = controller.dockItems.indexOf(details.data);
            int targetIndex = index;
            if (draggedIndex < index) targetIndex -= 1;

            controller.updateDockItems(draggedIndex, targetIndex, details.data);
            controller.resetDragState();
          },
          builder: (context, candidateData, rejectedData) {
            return _buildButton(
              icon,
              hovered: index == controller.hoveredIndex.value,
              controller: controller,
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholderWidget(int index, DockController controller) {
    return DragTarget<IconData>(
      onWillAcceptWithDetails: (details) {
        controller.setPlaceholderIndex(index);
        return true;
      },
      onAcceptWithDetails: (details) {
        if (controller.placeholderIndex.value != null) {
          final int draggedIndex = controller.dockItems.indexOf(details.data);
          int targetIndex = controller.placeholderIndex.value!;
          if (draggedIndex < targetIndex) targetIndex -= 1;

          controller.updateDockItems(draggedIndex, targetIndex, details.data);
        }
        controller.resetDragState();
      },
      builder: (context, candidateData, rejectedData) {
        return _buildPlaceholder(hovered: candidateData.isNotEmpty);
      },
    );
  }

  Widget _buildPlaceholder({bool hovered = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: hovered ? Colors.transparent : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
      ),
    );
  }

  Widget _buildButton(IconData icon,
      {required bool hovered, required DockController controller}) {
    final int index = controller.dockItems.indexOf(icon);
    const double buttonSize = 55;
    const double iconScaleSize = 26;

    double scale = 1.0;
    if (controller.hoveredIndex.value != null) {
      final int distance = (controller.hoveredIndex.value! - index).abs();
      if (hovered) {
        scale = 1.3;
      } else if (distance == 1) {
        scale = 1.1;
      }
    }

    final double translateY = (1.3 - scale) * 12;
    final Color boxColor =
    Colors.primaries[icon.hashCode % Colors.primaries.length];

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      tween: Tween<double>(begin: 1.0, end: scale),
      builder: (context, animatedScale, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Transform.translate(
            offset: Offset(0, translateY),
            child: Transform.scale(
              scale: animatedScale,
              alignment: Alignment.bottomCenter,
              child: Container(
                width: buttonSize,
                height: buttonSize,
                decoration: BoxDecoration(
                  color: boxColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: iconScaleSize * scale,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}