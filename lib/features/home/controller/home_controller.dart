import 'package:boilerplate_flutter/models/user_model.dart';
import 'package:boilerplate_flutter/services/dialog_service.dart';
import 'package:flutter/material.dart';
import '../../../services/user_service.dart';

class HomeController with ChangeNotifier {
  final UserService _userService = UserService();

  List<UserModel> users = [];
  bool isLoading = false;
  bool isFetchingMore = false;
  bool hasMore = true;
  int _page = 0;
  final int _limit = 10;

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

    if (result.error != null) {
      DialogService.showCustomSnackbar(
        message: result.error!.message,
      );
    }
    if (result.isSuccess) {
      final newUsers = result.data!;
      if (newUsers.length < _limit) hasMore = false;
      users.addAll(newUsers);
      _page++;
    } else {
      debugPrint("Error: ${result.error?.message}");
    }

    isLoading = false;
    isFetchingMore = false;
    notifyListeners();
  }
}
