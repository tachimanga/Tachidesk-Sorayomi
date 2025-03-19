// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class SelectKey {
  final int categoryId;
  final int mangaId;

  SelectKey(this.categoryId, this.mangaId);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SelectKey &&
            other.categoryId == categoryId &&
            other.mangaId == mangaId);
  }

  @override
  int get hashCode => Object.hash(categoryId, mangaId);
}
