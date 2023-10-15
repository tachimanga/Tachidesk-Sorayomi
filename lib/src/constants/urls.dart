// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

enum AppUrls {
  sorayomiGithubUrl(url: "https://github.com/Suwayomi/Tachidesk-Sorayomi"),
  sorayomiLatestReleaseUrl(
      url: "https://github.com/Suwayomi/Tachidesk-Sorayomi/releases/latest"),
  tachideskHelp(url: "https://github.com/Suwayomi/Tachidesk-Server/wiki"),
  tachideskReddit(url: "https://www.reddit.com/r/Tachidesk"),
  sorayomiWhatsNew(
      url: "https://github.com/Suwayomi/Tachidesk-Sorayomi/releases/tag/"),
  telegram(url: "https://t.me/mangacrush"),
  discord(url: "https://discord.gg/CsnjRU35Rd"),
  iap(url: "https://mangacrushteam.github.io/iap.html"),
  terms(url: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"),
  privacy(url: "https://github.com/MangaCrushTeam/MangaCrush/blob/main/PRIVACY.md"),
  faqUrl(url: "https://tachimanga.github.io/help/faq/"),
  addRepo(url: "https://tachimanga.github.io/help/guides/adding-repos.html"),
  findAnswer(url: "https://tachimanga.github.io/help/guides/find-answer.html"),
  trackingHelp(url: "https://tachimanga.github.io/help/guides/tracking.html"),
  downloadHelp(url: "https://tachimanga.github.io/help/guides/downloads.html"),
  appstore(url: "https://apps.apple.com/us/app/tachimanga/id6447486175"),
  sorayomiLatestReleaseApiUrl(
    url:
        "https://api.github.com/repos/Suwayomi/Tachidesk-Sorayomi/releases/latest",
  );

  const AppUrls({required this.url});

  final String url;
}
