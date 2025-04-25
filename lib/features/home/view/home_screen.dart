import 'package:boilerplate_flutter/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/home_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<HomeController>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (scrollInfo.metrics.pixels ==
                    scrollInfo.metrics.maxScrollExtent) {
                  controller.loadUsers(isLoadMore: true);
                }
                return false;
              },
              child: ListView.builder(
                itemCount: controller.users.length +
                    (controller.isFetchingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < controller.users.length) {
                    final user = controller.users[index];
                    return ListTile(
                      title: Text(user.name),
                      subtitle: Text(user.email),
                    );
                  } else {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                },
              ),
            ),
    );
  }
}
