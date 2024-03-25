


class TraceRef {
  static Map<String, String> mangaToSourceMap = {};

  static void put(String? sourceId, String? mangaId) {
    //print("[traceInfo]put $sourceId, $mangaId");
    if (sourceId == null || mangaId == null) {
      return;
    }

    if (mangaToSourceMap.length > 300) {
      mangaToSourceMap.clear();
    }
    mangaToSourceMap[mangaId] = sourceId;
  }

  static String? get(String mangaId) {
    //print("[traceInfo]get $mangaId");
    return mangaToSourceMap[mangaId];
  }
}