import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:monekin/app/home/widgets/dashboard_account_list.dart';
import 'package:monekin/app/home/widgets/finance_health_donut.dart';
import 'package:monekin/app/home/widgets/new_transaction_fl_button.dart';
import 'package:monekin/app/layout/page_context.dart';
import 'package:monekin/app/layout/page_framework.dart';
import 'package:monekin/app/stats/stats_page.dart';
import 'package:monekin/app/stats/widgets/movements_distribution/pie_chart_by_categories.dart';
import 'package:monekin/core/database/services/user-setting/private_mode_service.dart';
import 'package:monekin/core/models/date-utils/date_period.dart';
import 'package:monekin/core/models/date-utils/date_period_state.dart';
import 'package:monekin/core/models/transaction/transaction_type.enum.dart';
import 'package:monekin/core/presentation/debug_page.dart';
import 'package:monekin/core/presentation/helpers/snackbar.dart';
import 'package:monekin/core/presentation/responsive/breakpoints.dart';
import 'package:monekin/core/presentation/responsive/page_content.dart';
import 'package:monekin/core/presentation/widgets/card_with_header.dart';
import 'package:monekin/core/presentation/widgets/dates/date_period_modal.dart';
import 'package:monekin/core/presentation/widgets/dates/date_range_chips.dart';
import 'package:monekin/core/presentation/widgets/income_expense_flow_card.dart';
import 'package:monekin/core/presentation/widgets/page_refresh.dart';
import 'package:monekin/core/presentation/widgets/tappable.dart';
import 'package:monekin/core/routes/route_utils.dart';
import 'package:monekin/core/utils/app_utils.dart';
import 'package:monekin/i18n/generated/translations.g.dart';

import '../../core/database/services/app-data/app_data_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  final _refreshKey = GlobalKey<PageRefreshState>();
  DatePeriodState dateRangeService = const DatePeriodState(
    datePeriod: defaultDatePeriod,
  );
  final ScrollController _scrollController = ScrollController();
  int _refreshVersion = 0;

  @override
  void initState() {
    super.initState();

    _loadSavedDatePeriod();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedDatePeriod() async {
    final savedPeriodJson = appStateData[AppDataKey.lastDashboardDatePeriod];

    if (savedPeriodJson != null) {
      try {
        final period = DatePeriod.fromJsonString(savedPeriodJson);
        if (!mounted) return;
        setState(() {
          dateRangeService = dateRangeService.copyWith(datePeriod: period);
        });
      } catch (_) {
        // Fall back to default
      }
    }
  }

  Future<void> _refreshDashboard() async {
    setState(() => _refreshVersion++);
  }

  void requestRefreshFocus() => _refreshKey.currentState?.requestFocus();

  void _onPeriodChanged(DatePeriod period) {
    AppDataService.instance.setItem(
      AppDataKey.lastDashboardDatePeriod,
      period.toJsonString(),
    );

    setState(() {
      dateRangeService = dateRangeService.copyWith(
        periodModifier: 0,
        datePeriod: period,
      );
    });
  }

  Future<void> _openDatePeriodSelector() async {
    final period = await openDatePeriodModal(
      context,
      DatePeriodModal(initialDatePeriod: dateRangeService.datePeriod),
    );

    if (period != null) _onPeriodChanged(period);
  }

  Future<void> _togglePrivateMode() async {
    final privateMode =
        await PrivateModeService.instance.privateModeStream.first;

    PrivateModeService.instance.setPrivateMode(!privateMode);
    await HapticFeedback.lightImpact();

    MonekinSnackbar.success(
      SnackbarParams(
        !privateMode
            ? t.settings.security.private_mode_activated
            : t.settings.security.private_mode_deactivated,
      ),
    );
  }

  bool _isWide(BuildContext context) =>
      BreakPoint.of(context).isLargerOrEqualTo(BreakpointID.md);

  /// On very large screens the income/expense flow cards join the left column
  /// (below the accounts card) instead of spanning a full-width row, giving the
  /// right column more vertical room.
  bool _isVeryWide(BuildContext context) =>
      BreakPoint.of(context).isLargerOrEqualTo(BreakpointID.xxl);

  @override
  Widget build(BuildContext context) {
    return PageFramework(
      title: t.home.title,
      enableAppBar: false,
      floatingActionButton: ifIsInTabs(context)
          ? null
          : NewTransactionButton(
              key: const Key('dashboard--new-transaction-button'),
              scrollController: _scrollController,
            ),
      body: SafeArea(
        bottom: false,
        child: PageRefresh(
          key: _refreshKey,
          onRefresh: _refreshDashboard,
          builder: (context, refreshButton) => SingleChildScrollView(
            controller: _scrollController,
            physics: AppUtils.hasPointerInput
                ? null
                : AlwaysScrollableScrollPhysics(
                    parent: ScrollConfiguration.of(context)
                        .getScrollPhysics(context),
                  ),
            padding: const EdgeInsets.only(bottom: 32),
            child: PageContent(child: _buildContent(context, refreshButton)),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Widget? refreshButton) {
    final isWide = _isWide(context);
    final isVeryWide = _isVeryWide(context);

    final flowCards = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: IncomeExpenseFlowCard(
              type: TransactionType.expense,
              periodState: dateRangeService,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: IncomeExpenseFlowCard(
              type: TransactionType.income,
              periodState: dateRangeService,
            ),
          ),
        ],
      ),
    );

    final accountsCard = DashboardAccountList(
      dateRangeService: dateRangeService,
      maxRowsToShow: isWide ? 5 : 3,
    );
    final healthCard = FinanceHealthCard(dateRangeService: dateRangeService);
    final categoriesCard = _buildCategoriesCard(context);

    // FORK: the total balance hero was removed; only the period picker remains.
    final periodSelector = _buildPeriodSelector(context);

    const gutter = EdgeInsets.symmetric(horizontal: 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _buildHeader(context, refreshButton),
        ),
        const SizedBox(height: 20),
        Padding(padding: gutter, child: periodSelector),
        const SizedBox(height: 16),
        Padding(
          key: ValueKey(_refreshVersion),
          padding: gutter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isVeryWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          flowCards,
                          const SizedBox(height: 16),
                          accountsCard,
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          healthCard,
                          const SizedBox(height: 16),
                          categoriesCard,
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                flowCards,
                const SizedBox(height: 16),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: accountsCard),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            healthCard,
                            const SizedBox(height: 16),
                            categoriesCard,
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  accountsCard,
                  const SizedBox(height: 16),
                  healthCard,
                  const SizedBox(height: 16),
                  categoriesCard,
                ],
              ],
              if (kDebugMode)
                TextButton(
                  onPressed: () => RouteUtils.pushRoute(const DebugPage()),
                  child: const Text('DEBUG PAGE'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------- Header -------------------------

  Widget _buildHeader(BuildContext context, Widget? refreshButton) {
    return Row(
      children: [
        // FORK: the user info (avatar, greeting, name) is not shown
        const Spacer(),
        ?refreshButton,
        if (refreshButton != null) const SizedBox(width: 8),
        _buildPrivateModeButton(context),
      ],
    );
  }

  Widget _buildPrivateModeButton(BuildContext context) {
    return Tappable(
      bgColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const CircleBorder(),
      onTap: _togglePrivateMode,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: StreamBuilder(
          stream: PrivateModeService.instance.privateModeStream,
          initialData: false,
          builder: (context, snapshot) {
            return Icon(
              (snapshot.data ?? false)
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface,
            );
          },
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FilledButton.icon(
        onPressed: _openDatePeriodSelector,
        icon: const Icon(Icons.calendar_month_rounded, size: 18),
        label: Text(
          dateRangeService.getText(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
  }

  Widget _buildCategoriesCard(BuildContext context) {
    return CardWithHeader(
      title: t.stats.by_categories,
      bodyPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      headerAction: CardHeaderAction(
        onTap: () => RouteUtils.pushRoute(
          StatsPage(
            dateRangeService: dateRangeService,
            initialIndex: StatsTab.distribution,
          ),
        ),
      ),
      body: PieChartByCategories(datePeriodState: dateRangeService),
    );
  }
}
