import 'dart:io' as io;
import 'dart:typed_data'; // For web

import 'package:chat_app/models/user_profile.dart';
import 'package:chat_app/service/database_service.dart';
import 'package:chat_app/service/storage_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:chat_app/service/navigation_service.dart';
import 'package:chat_app/service/alert_service.dart';
import 'package:chat_app/service/auth_service.dart';
import 'package:chat_app/service/media_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  dynamic selectedImage; // Can be io.File or Uint8List
  final GetIt _getIt = GetIt.instance;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AuthService _authService;
  late NavigationService _navigationService;
  late AlertService _alertService;
  late MediaService _mediaService;
  late StorageService _storageService;
  late DatabaseService _databaseService;

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _navigationService = _getIt.get<NavigationService>();
    _alertService = _getIt.get<AlertService>();
    _mediaService = _getIt.get<MediaService>();
    _storageService = _getIt.get<StorageService>();
    _databaseService = _getIt.get<DatabaseService>();
  }

  final RegExp emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  final RegExp passwordRegExp = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}$',
  );

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double maxWidth =
                      constraints.maxWidth < 400 ? constraints.maxWidth : 400;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Card(
                      elevation: 5.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Container(
                        width: maxWidth,
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isLoading)
                              const Center(
                                child: CircularProgressIndicator(),
                              )
                            else ...[
                              const Text(
                                'Register to Chatapp!',
                                style: TextStyle(
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              _pfpSelectionField(),
                              const SizedBox(height: 30.0),
                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _nameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Name',
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _formKey.currentState!.validate();
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 30.0),
                                    TextFormField(
                                      controller: _emailController,
                                      decoration: const InputDecoration(
                                        labelText: 'Email',
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _formKey.currentState!.validate();
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email';
                                        } else if (!emailRegExp
                                            .hasMatch(value)) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 30.0),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        border: const OutlineInputBorder(),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            color: Colors.grey,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _formKey.currentState!.validate();
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your password';
                                        } else if (!passwordRegExp
                                            .hasMatch(value)) {
                                          return 'Password must be at least 8 characters long, include an uppercase letter, a lowercase letter, a number, and a special character';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 30.0),
                                    TextFormField(
                                      controller: _confirmPasswordController,
                                      obscureText: _obscureConfirmPassword,
                                      decoration: InputDecoration(
                                        labelText: 'Confirm Password',
                                        border:const OutlineInputBorder(),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureConfirmPassword
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            color: Colors.grey,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscureConfirmPassword =
                                                  !_obscureConfirmPassword;
                                            });
                                          },
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _formKey.currentState!.validate();
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please confirm your password';
                                        } else if (value !=
                                            _passwordController.text) {
                                          return 'Passwords do not match';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 30.0),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  if (selectedImage == null) {
                                    _alertService.showToast(
                                        text: "Please select profile image ",
                                        icon: Icons.info);
                                  } else if ((_formKey.currentState
                                              ?.validate() ??
                                          false) &&
                                      selectedImage != null) {
                                    setState(() {
                                      isLoading = true;
                                    });
                                    _formKey.currentState?.save();
                                    bool result = await _authService.register(
                                        _emailController.text,
                                        _passwordController.text);
                                    if (result) {
                                      String? pfpUrl =
                                          await _storageService.uploadUserPfps(
                                              file: selectedImage!,
                                              uid: _authService.user!.uid);
                                      if (pfpUrl != null) {
                                        await _databaseService
                                            .createUserProfile(
                                                userProfile: UserProfile(
                                                    uid: _authService.user!.uid,
                                                    name: _nameController.text,
                                                    profileUrl: pfpUrl));
                                      } else {
                                        _alertService.showToast(
                                            text:
                                                "Failed to save profile picture, please try again!",
                                            icon: Icons.error);
                                      }
                                      setState(() {
                                        isLoading = false;
                                      });

                                      _alertService.showToast(
                                          text: "Registered Successfully!",
                                          icon: Icons.info);
                                      _navigationService
                                          .pushReplacementNamed("/home");
                                    } else {
                                      _alertService.showToast(
                                          text:
                                              "Failed to register, please try again!",
                                          icon: Icons.error);
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                child: const Text('Sign Up'),
                              ),
                              const SizedBox(height: 30.0),
                              TextButton(
                                onPressed: () {
                                  _navigationService.goBack();
                                },
                                child:
                                    const Text('Already a member? Sign in now'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pfpSelectionField() {
    return GestureDetector(
      onTap: () async {
        var file = await _mediaService.getImageFromGallery();
        if (file != null) {
          setState(() {
            if (kIsWeb) {
              // Ensure proper casting for web
              if (file is Uint8List) {
                selectedImage = file;
              }
            } else {
              // Handle non-web (e.g., mobile) case
              selectedImage = io.File(file.path);
            }
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20.0),
        width: 100.0,
        height: 100.0,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(50.0),
          image: selectedImage == null
              ? null
              : DecorationImage(
                  image: kIsWeb
                      ? MemoryImage(selectedImage) as ImageProvider
                      : FileImage(selectedImage) as ImageProvider,
                  fit: BoxFit.cover,
                ),
        ),
        child: selectedImage == null
            ? const Center(child: Icon(Icons.add_a_photo, size: 40.0))
            : null,
      ),
    );
  }
}
