import 'package:flutter/material.dart';

import 'number_or_add/number_or_add_widget.dart';
import 'nested_text_field/nested_text_field_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          body: SingleChildScrollView(
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Example 1:", style: Theme.of(context).textTheme.headlineLarge),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          "This example shows adding text fields to the form dynamically, triggering validations on changes, passing errors up the tree, and querying children for nested_text_field status before taking a save action.\n\nThe only invalid text is blank. <hit enter to trigger save action>",
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      const NestableTextFieldWidget(
                          uniqueId: "nestabletextfield.root", child: AddNestedTextFieldWidget(uniqueId: "nested")),
                      const Divider(height: 128, thickness: 2, color: Colors.black),
                      Text("Example 2:", style: Theme.of(context).textTheme.headlineLarge),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          "This example builds a dynamic tree adding the values of the branches. Demonstrating how a parent can query specific children directly.",
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      NumberOrAddWidget(uniqueId: "numberoradd.root"),
                    ],
                  )))),
    );
  }
}
