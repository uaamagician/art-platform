import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      initialData: AuthService().currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: const Text('個人檔案'),
            actions: [
              if (user != null)
                TextButton(
                  onPressed: () => AuthService().signOut(),
                  child: const Text('登出'),
                ),
            ],
          ),
          body: Center(
            child: user == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('登入後即可管理你的作品與個人資訊'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        ),
                        child: const Text('使用 Google 登入'),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (user.photoURL != null)
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(user.photoURL!),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        user.displayName ?? '',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(user.email ?? ''),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
