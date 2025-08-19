import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/urls.dart';
import '../../routes/router_config.dart';
import '../../utils/extensions/custom_extensions.dart';
import '../../utils/log.dart';
import 'domain/page_model.dart';

MdPage buildGetStartedPage(BuildContext context) {
  String content = """
${context.l10n!.get_started_summary}

## ${context.l10n!.get_started_local_source_title("📁")}
${context.l10n!.get_started_local_source_content(AppUrls.localSourceHelp.url)}

## ${context.l10n!.get_started_external_source_title("🌐")}
${context.l10n!.get_started_external_source_content([
    Routes.settings,
    Routes.browseSettings,
    Routes.editRepo,
  ].toPath)}

> ${context.l10n!.md_page_tips("💡")}
> ${context.l10n!.get_started_tips_1}

> ${context.l10n!.md_page_tips("💡")}
> ${context.l10n!.get_started_tips_2}
""";

  return MdPage(title: context.l10n!.get_start, content: content);
}

MdPage buildFindRepoPage(BuildContext context) {
  String content = """
## ${context.l10n!.how_to_find_repository_title}
${context.l10n!.how_to_find_repository_content}

> ${context.l10n!.md_page_tips("💡")}
> ${context.l10n!.get_started_tips_1}

> ${context.l10n!.md_page_tips("💡")}
> ${context.l10n!.get_started_tips_2}
""";

  return MdPage(title: context.l10n!.find_repository, content: content);
}

MdPage buildUnknownPage(BuildContext context) {
  return MdPage(title: "Page not found", content: "Page not found");
}
