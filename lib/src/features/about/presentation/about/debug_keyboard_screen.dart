// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import '../../../../utils/extensions/custom_extensions.dart';

class DebugKeyboardScreen extends StatelessWidget {
  const DebugKeyboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const appTitle = 'Form Styling Demo';
    return Scaffold(
        appBar: AppBar(
          title: const Text(appTitle),
        ),
        body: const MyCustomForm(),
    );
  }
}

class MyCustomForm extends StatelessWidget {
  const MyCustomForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text("Hello world 中文 displayLarge", style: context.textTheme.displayLarge,),
        Text("Hello world 中文 displayMedium", style: context.textTheme.displayMedium,),
        Text("Hello world 中文 displaySmall", style: context.textTheme.displaySmall,),
        Text("Hello world 中文 headlineLarge", style: context.textTheme.headlineLarge,),
        Text("Hello world 中文 headlineMedium", style: context.textTheme.headlineMedium,),
        Text("Hello world 中文 headlineSmall", style: context.textTheme.headlineSmall,),
        Text("Hello world 中文 titleLarge", style: context.textTheme.titleLarge,),
        Text("Hello world 中文 titleMedium", style: context.textTheme.titleMedium,),
        Text("Hello world 中文 titleSmall", style: context.textTheme.titleSmall,),
        Text("Hello world 中文 bodyLarge", style: context.textTheme.bodyLarge,),
        Text("Hello world 中文 bodyMedium", style: context.textTheme.bodyMedium,),
        Text("Hello world 中文 bodySmall", style: context.textTheme.bodySmall,),
        Text("Hello world 中文 labelLarge", style: context.textTheme.labelLarge,),
        Text("Hello world 中文 labelMedium", style: context.textTheme.labelMedium,),
        Text("Hello world 中文 labelSmall", style: context.textTheme.labelSmall,),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: TextField(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter a search term',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: TextFormField(
            decoration: const InputDecoration(
              border: UnderlineInputBorder(),
              labelText: 'Enter your username',
            ),
          ),
        ),
      ],
    );
  }
}