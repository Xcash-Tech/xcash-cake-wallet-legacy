import 'package:cake_wallet/src/screens/dashboard/widgets/order_row.dart';
import 'package:cake_wallet/view_model/dashboard/order_list_item.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/header_row.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/date_section_raw.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/transaction_raw.dart';
import 'package:cake_wallet/view_model/dashboard/transaction_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/date_section_item.dart';
import 'package:intl/intl.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';

class TransactionsPage extends StatefulWidget {
  TransactionsPage({@required this.dashboardViewModel});

  final DashboardViewModel dashboardViewModel;

  @override
  _TransactionsPageState createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  ScrollController _scrollController;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load more when near the bottom (80% scrolled)
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !widget.dashboardViewModel.hasMoreTransactions) {
      return;
    }
    
    setState(() => _isLoadingMore = true);
    
    try {
      await widget.dashboardViewModel.loadMoreTransactions();
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        bottom: 24
      ),
      child: Column(
        children: <Widget>[
          HeaderRow(dashboardViewModel: widget.dashboardViewModel),
          Expanded(
            child: Observer(
                builder: (_) {
                  final items = widget.dashboardViewModel.items;
                  final hasMore = widget.dashboardViewModel.hasMoreTransactions;
                  // Add 1 for loading indicator if there are more to load
                  final itemCount = (items?.length ?? 0) + (hasMore ? 1 : 0);

                  return items?.isNotEmpty ?? false
                    ? ListView.builder(
                      controller: _scrollController,
                      itemCount: itemCount,
                      itemBuilder: (context, index) {
                        // Show loading indicator at the end
                        if (index >= items.length) {
                          return Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: _isLoadingMore
                                ? CircularProgressIndicator()
                                : Text(
                                    'Scroll to load more...',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryTextTheme.caption.color,
                                    ),
                                  ),
                            ),
                          );
                        }

                        final item = items[index];

                        if (item is DateSectionItem) {
                          return DateSectionRaw(date: item.date);
                        }

                        if (item is TransactionListItem) {
                          final transaction = item.transaction;

                          return Observer(
                              builder: (_) => TransactionRow(
                              onTap: () => Navigator.of(context).pushNamed(
                                  Routes.transactionDetails,
                                  arguments: transaction),
                              direction: transaction.direction,
                              formattedDate: DateFormat('dd.MM.yy HH:mm:ss')
                                  .format(transaction.date),
                              formattedAmount: item.formattedCryptoAmount,
                              formattedFiatAmount: item.formattedFiatAmount,
                              isPending: transaction.isPending));
                        }

                        if (item is OrderListItem) {
                          final order = item.order;

                          return Observer(builder: (_) => OrderRow(
                            onTap: () => Navigator.of(context).pushNamed(
                                Routes.orderDetails,
                                arguments: order),
                            provider: order.provider,
                            from: order.from,
                            to: order.to,
                            createdAtFormattedDate:
                            DateFormat('HH:mm').format(order.createdAt),
                            formattedAmount: item.orderFormattedAmount,
                          ));
                        }

                        return Container(
                            color: Colors.transparent,
                            height: 1);
                      }
                  )
                  : Center(
                    child: Text(
                      S.of(context).placeholder_transactions,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).primaryTextTheme
                            .overline.decorationColor
                      ),
                    ),
                  );
                }
            )
          )
        ],
      ),
    );
  }
}
