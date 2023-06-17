extension Sequence where Iterator.Element: Hashable {
  func uniqued() -> [Iterator.Element] {
    var seen: Set<Iterator.Element> = []
    return filter { seen.insert($0).inserted }
  }
}
