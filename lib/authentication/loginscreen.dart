import 'dart:convert';
import 'package:doctor_doom/authentication/signupscreen.dart';
import 'package:doctor_doom/authentication/tokenmanage.dart';
import 'package:doctor_doom/homescreen/homescreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

final passwordVisibilityProvider = StateProvider<bool>((ref) => true);

class LoginScreen extends ConsumerWidget {
  const LoginScreen({Key? key}) : super(key: key);

  bool isEmailValid(String email) {
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return regex.hasMatch(email);
  }

  Future<void> login(WidgetRef ref) async {
    final email = ref.read(emailProvider);
    final password = ref.read(passwordProvider);
    if (!isEmailValid(email)) {
      ScaffoldMessenger.of(ref.context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid email address!")),
      );
      return;
    }

    const String url = "https://huddlehub-75fx.onrender.com/login/";

    final body = {
      "email": email,
      "password": password,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final data = response.body;

      if (response.statusCode == 200) {
        if (data == "Please enter valid password") {
          ScaffoldMessenger.of(ref.context).showSnackBar(
            SnackBar(content: Text("Invalid password. Please try again.")),
          );
        } else if (data == "Error occured") {
          ScaffoldMessenger.of(ref.context).showSnackBar(
            SnackBar(content: Text("User doesn't exist. Please try again.")),
          );
        } else {
          final token = data.split('=')[1];
          await saveToken(token);
          ScaffoldMessenger.of(ref.context).showSnackBar(
            SnackBar(content: Text("Login Successful!")),
          );

          Navigator.pushReplacement(
            ref.context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(ref.context).showSnackBar(
        SnackBar(content: Text("Error: $e.")),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _obscurePassword = ref.watch(passwordVisibilityProvider);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/loginbackground.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            children: [
              Padding(
                  padding: const EdgeInsets.only(top: 50.0),
                  child: Text(
                    "Dr. Doom",
                    style: GoogleFonts.kablammo(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 0, 0, 0),
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  )),
              const Spacer(flex: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(200, 255, 255, 255),
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'LOGIN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: "Email",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) =>
                            ref.read(emailProvider.notifier).state = value,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        decoration: InputDecoration(
                          labelText: "Password",
                          border: OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              ref
                                  .read(passwordVisibilityProvider.notifier)
                                  .state = !_obscurePassword;
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
                        onChanged: (value) =>
                            ref.read(passwordProvider.notifier).state = value,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => login(ref),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromRGBO(202, 239, 184, 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                        ),
                        child: const Text(
                          "Login",
                          style: TextStyle(
                              fontSize: 16,
                              color: Color.fromARGB(255, 0, 0, 0)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("New user? "),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SignupScreen()),
                              );
                            },
                            child: const Text(
                              "Register",
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ],
      ),
    );
  }
}