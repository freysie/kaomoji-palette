extension Collection {
  /// Returns the element at the specified index if it is within bounds, otherwise nil.
  subscript(orNil index: Index) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}
