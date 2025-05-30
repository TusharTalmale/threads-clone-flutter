import 'package:flutter/material.dart';
import 'package:form_validator/form_validator.dart';
import 'package:get/get.dart';
import 'package:thread_app/Route/route_namess.dart';
import 'package:thread_app/controller/auth_controller.dart';
import 'package:thread_app/widgets/auth_input.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController(text: "");
  final TextEditingController emailController = TextEditingController(text: "");
  final TextEditingController passController = TextEditingController(text: "");
  final TextEditingController confirmPassController = TextEditingController(
    text: "",
  );
  AuthController controller = Get.put(AuthController());
@override
void dispose(){
  nameController.dispose();
  emailController.dispose();
passController.dispose();
confirmPassController.dispose();
  super.dispose();
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Form(
              key: _form,
              child: Column(
                children: [
                  // Logo/Image (reusing the same asset)
                  SizedBox(
                    height: 80,
                    width: 80,
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors
                            .white, // Assuming a white logo on a dark background or for styling
                        BlendMode.srcIn,
                      ),
                      child: Image.asset(
                        'assets/images/logos.png', // Ensure this asset exists
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Header Text
                  Align(
                    alignment: Alignment.topLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(
                                  context,
                                ).textTheme.headlineLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Join us to connect with the world!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),
                  //Name Input
                  AuthInput(
                    label: "Name",
                    hintText: "Enter your Name",
                    controller: nameController,
                    validatorCallback:
                        ValidationBuilder()
                            .required()
                            .minLength(3)
                            .maxLength(50)
                            .build(),
                  ),
                  const SizedBox(height: 20),
                  // Email Input
                  AuthInput(
                    label: "Email",
                    hintText: "Enter your Email",
                    controller: emailController,
                    validatorCallback:
                        ValidationBuilder()
                            .email()
                            .required()
                            .maxLength(50)
                            .build(),
                  ),
                  const SizedBox(height: 20),
                  // Password Input
                  AuthInput(
                    label: "Password",
                    hintText: "Create a Password",
                    isPass: true,
                    controller: passController,
                    validatorCallback:
                        ValidationBuilder()
                            .required()
                            .minLength(6)
                            .maxLength(50)
                            .build(),
                  ),
                  const SizedBox(height: 20),
                  // Confirm Password Input
                  AuthInput(
                    label: "Confirm Password",
                    hintText: "Re-enter your Password",
                    isPass: true,
                    controller: confirmPassController,
                    validatorCallback: (arg) {
                      if (passController.text != arg) {
                        return "password not matched";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Sign Up Button
                  SizedBox(
                    width: double.infinity,
                    child: Obx(
                      () => ElevatedButton(
                        onPressed:
                            controller.registerLoading.value
                                ? null
                                : () {
                                  if (_form.currentState!.validate()) {
                                    controller.register(
                                       nameController.text.trim(),
                                      emailController.text.trim(),
                                      confirmPassController.text.trim(),
                                    );
                                  }
                                },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child:
                            controller.registerLoading.value
                                ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.red,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Link to Login Page
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account? ",
                        style: TextStyle(fontSize: 15),
                      ),
                      GestureDetector(
                        onTap: () {
                          Get.toNamed(RouteNamess.login);
                        },
                        child: Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                            decoration: TextDecoration.underline,
                            decorationColor: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
