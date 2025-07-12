import 'package:flutter/material.dart';
import 'package:flutter_projects/config/performance_config.dart';

class OptimizedListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final bool isLoading;
  final bool hasMore;
  final VoidCallback? onLoadMore;
  final Widget? loadingWidget;
  final Widget? emptyWidget;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const OptimizedListView({
    Key? key,
    required this.items,
    required this.itemBuilder,
    this.isLoading = false,
    this.hasMore = false,
    this.onLoadMore,
    this.loadingWidget,
    this.emptyWidget,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  }) : super(key: key);

  @override
  State<OptimizedListView<T>> createState() => _OptimizedListViewState<T>();
}

class _OptimizedListViewState<T> extends State<OptimizedListView<T>> {
  bool _isLoadingMore = false;

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && !widget.isLoading) {
      return widget.emptyWidget ?? _buildEmptyWidget();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: ListView.builder(
        controller: widget.controller,
        padding: widget.padding,
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics,
        itemCount: _getItemCount(),
        itemBuilder: (context, index) {
          if (index >= widget.items.length) {
            return _buildLoadingMoreWidget();
          }
          return widget.itemBuilder(context, widget.items[index], index);
        },
      ),
    );
  }

  int _getItemCount() {
    int count = widget.items.length;
    if (widget.hasMore && (widget.isLoading || _isLoadingMore)) {
      count += 1;
    }
    return count;
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification) {
      final metrics = notification.metrics;
      if (metrics.pixels >= metrics.maxScrollExtent - 200) {
        _loadMoreIfNeeded();
      }
    }
    return false;
  }

  void _loadMoreIfNeeded() {
    if (widget.hasMore &&
        !widget.isLoading &&
        !_isLoadingMore &&
        widget.onLoadMore != null) {
      setState(() {
        _isLoadingMore = true;
      });

      widget.onLoadMore!();

      Future.delayed(PerformanceConfig.normalAnimation, () {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
          });
        }
      });
    }
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No hay elementos para mostrar',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMoreWidget() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Center(
        child: widget.loadingWidget ?? CircularProgressIndicator(),
      ),
    );
  }
}
