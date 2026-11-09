import 'package:drift/drift.dart' as drift;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:monekin/app/categories/selectors/category_button_selector.dart';
import 'package:monekin/app/categories/selectors/draggableScrollableKeyboardAware.mixin.dart';
import 'package:monekin/core/database/services/category/category_service.dart';
import 'package:monekin/core/database/utils/drift_utils.dart';
import 'package:monekin/core/extensions/color.extensions.dart';
import 'package:monekin/core/extensions/string.extension.dart';
import 'package:monekin/core/models/category/category.dart';
import 'package:monekin/core/models/supported-icon/icon_displayer.dart';
import 'package:monekin/core/presentation/animations/animated_expanded.dart';
import 'package:monekin/core/presentation/app_colors.dart';
import 'package:monekin/core/presentation/theme.dart';
import 'package:monekin/core/presentation/widgets/bottomSheetFooter.dart';
import 'package:monekin/core/presentation/widgets/modal_container.dart';
import 'package:monekin/core/presentation/widgets/scrollable_with_bottom_gradient.dart';
import 'package:monekin/core/routes/route_utils.dart';
import 'package:monekin/i18n/generated/translations.g.dart';

Future<Category?> showCategoryPickerModal(
  BuildContext context, {
  required CategoryPicker modal,
}) {
  return RouteUtils.showResponsiveModal<Category>(
    context,
    builder: (context) {
      return modal;
    },
  );
}

/// Places [newVisibleOrder] (a reordered subset of [allIds]) back into the
/// slots the subset occupied in [allIds], leaving the other ids where they are.
// FORK: used to persist drag-and-drop ordering of a filtered category list
List<String> reorderSubset(List<String> allIds, List<String> newVisibleOrder) {
  final visible = newVisibleOrder.toSet();
  final queue = newVisibleOrder.iterator;

  return [
    for (final id in allIds)
      if (visible.contains(id) && queue.moveNext()) queue.current else id,
  ];
}

class CategoryPicker extends StatefulWidget {
  CategoryPicker({
    super.key,
    required this.selectedCategory,
    required this.categoryType,
    this.showSubcategories = true,
    this.excludeCategoriesWithId = const [],
  }) : assert(categoryType.isNotEmpty);

  final Category? selectedCategory;
  final List<CategoryType> categoryType;

  /// IDs of categories to exclude from the list
  final List<String> excludeCategoriesWithId;

  final bool showSubcategories;

  @override
  State<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<CategoryPicker>
    with DraggableScrollableKeyboardAware {
  Category? selectedCategory;

  final searchContoller = TextEditingController();

  /// In a popover, set right after the user taps a top-level category so the
  /// subcategory stream can decide whether to auto-close (leaf) or stay open to
  /// let the user refine.
  bool _awaitingSubcatCheck = false;

  /// Ids in the order set by the last drag, until the DB stream catches up.
  List<String>? _localOrder;

  Future<void> _moveCategory(
    List<Category> visible,
    Category dragged,
    Category target,
  ) async {
    final ids = visible.map((c) => c.id).toList();
    final to = ids.indexOf(target.id);

    ids
      ..remove(dragged.id)
      ..insert(to, dragged.id);

    setState(() => _localOrder = ids);
    await HapticFeedback.selectionClick();

    final all = await CategoryService.instance
        .getCategories(predicate: (c, p) => c.parentCategoryID.isNull())
        .first;

    final newOrder = reorderSubset(all.map((c) => c.id).toList(), ids);
    final byId = {for (final c in all) c.id: c};

    await Future.wait([
      for (final (index, id) in newOrder.indexed)
        if (byId[id]!.displayOrder != index)
          CategoryService.instance.updateCategory(
            byId[id]!.copyWith(displayOrder: index),
          ),
    ]);

    if (mounted) setState(() => _localOrder = null);
  }

  @override
  void initState() {
    super.initState();

    selectedCategory = widget.selectedCategory;
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);

    final sheet = buildDraggableSheet(
      minChildSize: 0.64,
      defaultSize: 0.65,
      builder: (context, scrollController) {
        return ModalContainer(
          title: t.categories.select.select_one,
          //subtitle: "Categoría seleccionada: Compras",
          titleBuilder: (title) {
            return Row(
              children: [
                Text(title),
                // if (selectedCategory != null) ...[
                //   const SizedBox(width: 8),
                //   IconDisplayer.fromCategory(context,
                //       category: selectedCategory!)
                // ]
              ],
            );
          },
          // endWidget:
          //     IconButton(onPressed: () {}, icon: Icon(Icons.more_vert)),
          body: StreamBuilder(
            stream: CategoryService.instance.getCategories(
              predicate: (c, p) => buildDriftExpr([
                c.parentCategoryID.isNull(),
                c.type.isInValues(widget.categoryType),
                c.id.isNotIn(widget.excludeCategoriesWithId),
                drift.Expression.or([
                  c.name.contains(searchContoller.text),
                  if (selectedCategory != null)
                    c.id.isValue(
                      selectedCategory?.parentCategoryID ??
                          selectedCategory!.id,
                    ),
                ]),
              ]),
            ),
            builder: (context, snapshot) {
              return Column(
                children: [
                  TextFormField(
                    controller: searchContoller,
                    focusNode: searchFocusNode,
                    autofocus: ModalPresentation.isPopover(context),
                    decoration: InputDecoration(
                      filled: false,
                      isDense: false,
                      hintText: t.currencies.search,
                      labelText: t.general.tap_to_search,
                      floatingLabelStyle: const TextStyle(height: -0.0005),
                      prefixIcon: const Icon(Icons.search),
                      border: const UnderlineInputBorder(),
                    ),
                    onChanged: (value) {
                      rebuild();
                    },
                  ),
                  //  buildSelectAllButton(snapshot),
                  Expanded(
                    child: ScrollableWithBottomGradient(
                      gradientColor: AppColors.of(context).modalBackground,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      controller: scrollController,
                      child: buildCategoryList(snapshot, scrollController),
                    ),
                  ),
                ],
              );
            },
          ),
          footer: Column(
            children: [
              // ---- SUBCATEGORY SELECTOR ----
              if (selectedCategory != null && widget.showSubcategories)
                StreamBuilder(
                  stream: CategoryService.instance.getCategories(
                    predicate: (catTable, parentCatTable) =>
                        catTable.parentCategoryID.isValue(
                          selectedCategory!.parentCategoryID ??
                              selectedCategory!.id,
                        ),
                  ),
                  builder: (context, snapshot) {
                    final subcategories = snapshot.data;

                    // Popover leaf-close: once we know the tapped category has
                    // no subcategories, commit it and close (there is no save
                    // button). Categories with subcategories stay open to refine.
                    if (_awaitingSubcatCheck &&
                        ModalPresentation.isPopover(context) &&
                        snapshot.hasData) {
                      _awaitingSubcatCheck = false;
                      if (subcategories!.isEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          RouteUtils.popRoute(selectedCategory);
                        });
                      }
                    }

                    return AnimatedExpanded(
                      axis: Axis.vertical,
                      expand: snapshot.hasData && snapshot.data!.isNotEmpty,
                      duration: const Duration(milliseconds: 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  '${t.categories.subcategories}:',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium!
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 4),
                              buildSubcategoryRow(context, subcategories),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  },
                ),

              //  -- End subcategory selector --
              if (!ModalPresentation.isPopover(context))
                BottomSheetFooter(
                  onSaved: selectedCategory == null
                      ? null
                      : () {
                          RouteUtils.popRoute(selectedCategory);
                        },
                ),
            ],
          ),
        );
      },
    );

    // A parent-only selection (or one refined via subcategory chips) has no
    // save button in a popover: commit whatever is selected on dismiss.
    return PopoverCommitOnDismiss(
      onCommit: () => RouteUtils.popRoute(selectedCategory),
      child: sheet,
    );
  }

  SingleChildScrollView buildSubcategoryRow(
    BuildContext context,
    List<Category>? subcategories,
  ) {
    final isDarkMode = isAppInDarkBrightness(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final subcat in subcategories ?? []) ...[
            ChoiceChip.elevated(
              selected: selectedCategory?.id == subcat.id,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: selectedCategory?.id == subcat.id
                      ? ColorHex.get(selectedCategory!.color)
                      : ColorHex.get(selectedCategory!.color).lighten(),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              label: Text(
                subcat.name,
                style: TextStyle(
                  color: selectedCategory?.id == subcat.id
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              showCheckmark: false,
              selectedColor: selectedCategory != null
                  ? ColorHex.get(selectedCategory!.color)
                  : null,
              avatar: IconDisplayer(
                supportedIcon: subcat.icon,
                mainColor: selectedCategory?.id == subcat.id
                    ? Colors.white
                    : ColorHex.get(subcat.color).lighten(
                        isDarkMode ? IconDisplayer.darkLightenFactor : 0,
                      ),
                secondaryColor: Colors.transparent,
                padding: 0,
              ),
              onSelected: (selected) {
                // In a popover, picking a subcategory is a final choice.
                if (ModalPresentation.isPopover(context)) {
                  RouteUtils.popRoute(
                    selected ? subcat : subcat.parentCategory,
                  );
                  return;
                }

                if (selected) {
                  selectedCategory = subcat;
                } else {
                  selectedCategory = subcat.parentCategory;
                }

                rebuild();
              },
            ),
            const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }

  Widget buildCategoryList(
    AsyncSnapshot<List<Category>> snapshot,
    ScrollController sc,
  ) {
    if (!snapshot.hasData) {
      return const LinearProgressIndicator();
    }

    var categories = snapshot.data!;

    if (_localOrder != null) {
      final order = _localOrder!;
      categories = [...categories]
        ..sort((a, b) {
          final ia = order.indexOf(a.id);
          final ib = order.indexOf(b.id);
          return (ia < 0 ? order.length : ia).compareTo(
            ib < 0 ? order.length : ib,
          );
        });
    }

    // Reordering is disabled while searching, as the list is partial
    final canReorder = categories.length > 1 && searchContoller.text.isEmpty;

    return Align(
      alignment: Alignment.center,
      heightFactor: 1,
      child: Wrap(
        runAlignment: WrapAlignment.center,
        runSpacing: 20, // Vertical space
        spacing: 16, // Horizontal space
        children: categories.map((category) {
          final item = CategoryButtonSelector(
            label: category.name,
            maxTextSize: 48 * 1.25,
            iconWidget: IconDisplayer.fromCategory(
              context,
              category: category,
              borderRadius: 99999,
              size: 38,
              isOutline:
                  selectedCategory?.id == category.id ||
                  selectedCategory?.parentCategoryID == category.id,
              onTap: () {
                HapticFeedback.lightImpact();

                // In a popover with no subcategory step, a top-level tap is the
                // final choice.
                if (ModalPresentation.isPopover(context) &&
                    !widget.showSubcategories) {
                  RouteUtils.popRoute(category);
                  return;
                }

                selectedCategory = category;

                if (searchContoller.text.isNotNullNorEmpty) {
                  searchContoller.text = '';
                }

                // Let the subcategory stream decide whether to auto-close.
                _awaitingSubcatCheck = ModalPresentation.isPopover(context);

                rebuild();
              },
            ),
          );

          // FORK: long press and drag onto another category to reorder
          return DragTarget<Category>(
            onWillAcceptWithDetails: (details) =>
                canReorder && details.data.id != category.id,
            onAcceptWithDetails: (details) =>
                _moveCategory(categories, details.data, category),
            builder: (context, candidates, _) => AnimatedScale(
              scale: candidates.isNotEmpty ? 1.15 : 1,
              duration: const Duration(milliseconds: 120),
              child: LongPressDraggable<Category>(
                data: category,
                maxSimultaneousDrags: canReorder ? 1 : 0,
                onDragStarted: HapticFeedback.mediumImpact,
                feedback: Material(
                  color: Colors.transparent,
                  child: Transform.scale(scale: 1.15, child: item),
                ),
                childWhenDragging: Opacity(opacity: 0.3, child: item),
                child: item,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
