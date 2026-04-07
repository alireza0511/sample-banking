import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';

/// Modal for editing which quick actions appear on the hub
class EditActionsModal extends StatefulWidget {
  final List<String> allActions;
  final List<String> selectedActions;
  final Function(List<String>) onSelectionChanged;

  const EditActionsModal({
    super.key,
    required this.allActions,
    required this.selectedActions,
    required this.onSelectionChanged,
  });

  @override
  State<EditActionsModal> createState() => _EditActionsModalState();
}

class _EditActionsModalState extends State<EditActionsModal> {
  late List<String> tempSelection;

  @override
  void initState() {
    super.initState();
    tempSelection = List.from(widget.selectedActions);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLg),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Quick Actions',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton(
                      onPressed: () {
                        widget.onSelectionChanged(tempSelection);
                        Navigator.pop(context);
                      },
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // Actions list
              Expanded(
                child: ReorderableListView.builder(
                  scrollController: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: widget.allActions.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = tempSelection.removeAt(oldIndex);
                      tempSelection.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final action = widget.allActions[index];
                    final isSelected = tempSelection.contains(action);

                    return CheckboxListTile(
                      key: ValueKey(action),
                      title: Text(action),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            if (!tempSelection.contains(action)) {
                              tempSelection.add(action);
                            }
                          } else {
                            tempSelection.remove(action);
                          }
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      secondary: const Icon(Icons.drag_handle),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
