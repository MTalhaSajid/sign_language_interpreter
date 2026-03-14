import 'package:flutter/material.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../../../services/dialog_service.dart';
import '../model/user_model.dart';
import '../service/user_service.dart';

class HomeController extends ChangeNotifier {
  final UserService _userService;

  HomeController(this._userService);

  List<UserModel> users = [];
  bool isLoading = false;
  bool isFetchingMore = false;
  bool hasMore = true;
  int _page = 0;
  final int _limit = AppConstants.kDefaultPageLimit;

  Future<void> loadUsers({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isFetchingMore || !hasMore) return;
      isFetchingMore = true;
      notifyListeners();
    } else {
      isLoading = true;
      notifyListeners();
    }

    final result =
        await _userService.fetchUsers(start: _page * _limit, limit: _limit);

    if (result.isSuccess) {
      final newUsers = result.data!;
      if (newUsers.length < _limit) hasMore = false;
      users.addAll(newUsers);
      _page++;
      AppLogger.i('Loaded ${newUsers.length} users (page $_page)');
    } else {
      AppLogger.e('Failed to load users', result.error);
      DialogService.showCustomSnackbar(
        message: result.error!.message,
        icon: Icons.error_outline,
        backgroundColor: Colors.red.shade700,
      );
    }

    isLoading = false;
    isFetchingMore = false;
    notifyListeners();
  }
}
