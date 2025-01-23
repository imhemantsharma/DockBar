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
  var dockItems = <IconData>[Icons.person, Icons.message, Icons.call, Icons.camera, Icons.photo].obs;
  var draggingIndex = RxnInt();
  var placeholderIndex = RxnInt();
  var hoveredIndex = RxnInt();

  void setDraggingIndex(int? index) {
    draggingIndex.value = index;
  }

  void setPlaceholderIndex(int? index) {
    placeholderIndex.value = index;
  }

  void setHoveredIndex(int? index) {
    hoveredIndex.value = index;
  }

  void updateDockItems(int draggedIndex, int targetIndex, IconData data) {
    dockItems.removeAt(draggedIndex);
    dockItems.insert(targetIndex, data);
  }
}

class Dock extends StatelessWidget {
  const Dock({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DockController());

    return SizedBox(
      height: 100,
      child: Obx(() => Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int index = 0; index < controller.dockItems.length; index++) ...[
            if (controller.draggingIndex.value != null && controller.placeholderIndex.value == index)
              _buildPlaceholderWidget(index, controller),
            if (controller.draggingIndex.value != index)
              _buildDraggableDockButton(index, controller),
          ],
        ],
      )),
    );
  }

  Widget _buildDraggableDockButton(int index, DockController controller) {
    IconData icon = controller.dockItems[index];
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
        onDragCompleted: () {
          controller.setDraggingIndex(null);
          controller.setPlaceholderIndex(null);
          controller.setHoveredIndex(null);
        },
        onDraggableCanceled: (_, __) {
          controller.setDraggingIndex(null);
          controller.setPlaceholderIndex(null);
          controller.setHoveredIndex(null);
        },
        child: DragTarget<IconData>(
          onWillAcceptWithDetails: (details) {
            controller.setPlaceholderIndex(index);
            return true;
          },
          onAcceptWithDetails: (details) {
            final draggedIndex = controller.dockItems.indexOf(details.data);
            int targetIndex = index;
            if (draggedIndex < index) targetIndex -= 1;

            controller.updateDockItems(draggedIndex, targetIndex, details.data);
            controller.setDraggingIndex(null);
            controller.setPlaceholderIndex(null);
            controller.setHoveredIndex(null);
          },
          builder: (context, candidateData, rejectedData) {
            return _buildButton(icon, hovered: index == controller.hoveredIndex.value, controller: controller);
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
          final draggedIndex = controller.dockItems.indexOf(details.data);
          int targetIndex = controller.placeholderIndex.value!;
          if (draggedIndex < targetIndex) targetIndex -= 1;

          controller.updateDockItems(draggedIndex, targetIndex, details.data);
        }
        controller.setDraggingIndex(null);
        controller.setPlaceholderIndex(null);
        controller.setHoveredIndex(null);
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

  Widget _buildButton(IconData icon, {required bool hovered, required DockController controller}) {
    double scale = 1.0;

    if (controller.hoveredIndex.value != null) {
      if (hovered) {
        scale = 1.2;
      } else {
        int distance = (controller.hoveredIndex.value! - controller.dockItems.indexOf(icon)).abs();
        scale = distance == 1 ? 1.1 : 1.0;
      }
    }

    Color boxColor = Colors.primaries[icon.hashCode % Colors.primaries.length];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 60 * scale,
      height: 60 * scale,
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: Icon(
          icon,
          color: Colors.white,
          size: 28 * scale,
        ),
      ),
    );
  }
}
