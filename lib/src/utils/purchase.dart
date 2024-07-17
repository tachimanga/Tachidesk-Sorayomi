

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/urls.dart';
import '../routes/router_config.dart';
import 'launch_url_in_web.dart';
import 'misc/toast/toast.dart';


Future<bool> checkPurchase(bool purchaseGate, bool testflightFlag,
    bool freeTrialFlag, BuildContext context, Toast toast) {
  final completer = Completer<bool>();

  if (purchaseGate) {
    completer.complete(true);
  }
  else {
    if (testflightFlag) {
      processTestflight(
          purchaseGate, testflightFlag, freeTrialFlag, context, toast, completer);
    }
    else {
      context.push(Routes.purchase);
      completer.complete(false);
    }
  }

  return completer.future;
}

void processTestflight(bool purchaseGate, bool testflightFlag,
    bool freeTrialFlag, BuildContext ctx, Toast toast, Completer<bool> completer) {
  if (freeTrialFlag) {
    showDialog(
      context: ctx,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('This is a Premium Feature'),
          content: const Text(
              'Please install the App Store one to complete the purchase and then switch back to the TestFlight one. '
                  'Alternatively, you can enjoy a free trial for 30 days.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                context.pop();
                completer.complete(false);
              },
            ),
            ElevatedButton(
              child: const Text('OK'),
              onPressed: () {
                context.pop();
                completer.complete(true);
              },
            ),
          ],
        );
      },
    );
  } else {
    showDialog(
      context: ctx,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('This is a Premium Feature'),
          content: const Text(
              'Please install the App Store one to complete the purchase and then switch back to the TestFlight one.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                context.pop();
              },
            ),
            ElevatedButton(
              child: const Text('OK'),
              onPressed: () {
                launchUrlInSafari(
                  context,
                  AppUrls.appstore.url,
                  toast,
                );
                context.pop();
              },
            ),
          ],
        );
      },
    );
    completer.complete(false);
  }
}