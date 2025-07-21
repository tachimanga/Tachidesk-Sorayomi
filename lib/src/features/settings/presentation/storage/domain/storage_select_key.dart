// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class SelectKey {
  // download v2
  final int? mangaId;
  // download v1
  final String? title;
  final String? source;

  SelectKey(this.mangaId, this.title, this.source);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SelectKey &&
            other.mangaId == mangaId &&
            other.title == title &&
            other.source == source);
  }

  @override
  int get hashCode => Object.hash(mangaId, title, source);
}